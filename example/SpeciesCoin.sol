// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SpeciesCoin is ERC20, AccessControl, ERC721Holder {
    bytes32 public constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public collectionAddress;
    uint256 public numberOfBlocksPerRewardUnit;
    uint256 public coinAmountPerRewardUnit;
    uint256 public welcomeBonusAmount;
    uint256 public amountOfStakers;
    uint256 public tokensStaked;
    uint256 public immutable contractCreationBlock;

    struct StakeInfo {
        uint256 stakedAtBlock;
        uint256 lastHarvestBlock;
        bool currentlyStaked;
    }
    /// owner => tokenId => StakeInfo
    mapping(address => mapping(uint256 => StakeInfo)) public stakeLog;
    /// owner => #NFTsStaked
    mapping(address => uint256) public tokensStakedByUser;
    /// tokenId => true/false (true if welcome bonus has been collected for a specific tokenId)
    mapping(uint256 => bool) public welcomeBonusCollected;
    /// owner => list of all tokenIds that the user has staked
    mapping(address => uint256[]) public stakePortfolioByUser;
    /// tokenId => indexInStakePortfolio
    mapping(uint256 => uint256) public indexOfTokenIdInStakePortfolio;

    event RewardsHarvested(address owner, uint256 amount);
    event NFTStaked(address owner, uint256 tokenId);
    event NFTUnstaked(address owner, uint256 tokenId);

    constructor(address owner, address _collectionAddress)
        ERC20("Species Coin", "SPCC")
        AccessControl()
    {
        _mint(owner, 200000 * 10**18);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(CONTRACT_ADMIN_ROLE, owner);
        _setupRole(BURNER_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        collectionAddress = _collectionAddress;
        contractCreationBlock = block.number;
        coinAmountPerRewardUnit = 10 * 10**18; // 10 ERC20 coins per rewardUnit, may be changed later on
        numberOfBlocksPerRewardUnit = 20571; // 12 hours per reward unit , may be changed later on
        welcomeBonusAmount = 200 * 10**18; // 200 tokens welcome bonus, only paid once per tokenId
    }

    function stakedNFTSByUser(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return stakePortfolioByUser[owner];
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        super._burn(from, amount);
    }

    function pendingRewards(address owner, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        StakeInfo memory info = stakeLog[owner][tokenId];

        if (
            info.lastHarvestBlock < contractCreationBlock ||
            info.currentlyStaked == false
        ) {
            return 0;
        }
        uint256 blocksPassedSinceLastHarvest = block.number -
            info.lastHarvestBlock;
        if (blocksPassedSinceLastHarvest < numberOfBlocksPerRewardUnit * 2) {
            return 0;
        }
        uint256 rewardAmount = blocksPassedSinceLastHarvest /
            numberOfBlocksPerRewardUnit -
            1;
        return rewardAmount * coinAmountPerRewardUnit;
    }

    function stake(uint256 tokenId) public {
        IERC721(collectionAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId
        );
        require(
            IERC721(collectionAddress).ownerOf(tokenId) == address(this),
            "SPCC: Error while transferring token"
        );
        StakeInfo storage info = stakeLog[_msgSender()][tokenId];
        info.stakedAtBlock = block.number;
        info.lastHarvestBlock = block.number;
        info.currentlyStaked = true;
        if (tokensStakedByUser[_msgSender()] == 0) {
            amountOfStakers += 1;
        }
        tokensStakedByUser[_msgSender()] += 1;
        tokensStaked += 1;
        stakePortfolioByUser[_msgSender()].push(tokenId);
        uint256 indexOfNewElement = stakePortfolioByUser[_msgSender()].length -
            1;
        indexOfTokenIdInStakePortfolio[tokenId] = indexOfNewElement;
        if (!welcomeBonusCollected[tokenId]) {
            _mint(_msgSender(), welcomeBonusAmount);
            welcomeBonusCollected[tokenId] = true;
        }

        emit NFTStaked(_msgSender(), tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) external {
        for (uint256 currentId = 0; currentId < tokenIds.length; currentId++) {
            if (tokenIds[currentId] == 0) {
                continue;
            }
            stake(tokenIds[currentId]);
        }
    }

    function unstakeBatch(uint256[] memory tokenIds) external {
        for (uint256 currentId = 0; currentId < tokenIds.length; currentId++) {
            if (tokenIds[currentId] == 0) {
                continue;
            }
            unstake(tokenIds[currentId]);
        }
    }

    function unstake(uint256 tokenId) public {
        if (pendingRewards(_msgSender(), tokenId) > 0) {
            harvest(tokenId);
        }
        StakeInfo storage info = stakeLog[_msgSender()][tokenId];
        info.currentlyStaked = true;
        IERC721(collectionAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId
        );
        require(
            IERC721(collectionAddress).ownerOf(tokenId) == _msgSender(),
            "SPCC: Error while transferring token"
        );
        if (tokensStakedByUser[_msgSender()] == 1) {
            amountOfStakers -= 1;
        }
        tokensStakedByUser[_msgSender()] -= 1;
        tokensStaked -= 1;
        stakePortfolioByUser[_msgSender()][
            indexOfTokenIdInStakePortfolio[tokenId]
        ] = 0;
        emit NFTUnstaked(_msgSender(), tokenId);
    }

    function harvest(uint256 tokenId) public {
        StakeInfo storage info = stakeLog[_msgSender()][tokenId];
        uint256 rewardAmountInERC20Tokens = pendingRewards(
            _msgSender(),
            tokenId
        );
        if (rewardAmountInERC20Tokens > 0) {
            info.lastHarvestBlock = block.number;
            _mint(_msgSender(), rewardAmountInERC20Tokens);
            emit RewardsHarvested(_msgSender(), rewardAmountInERC20Tokens);
        }
    }

    function harvestBatch(address user) external {
        uint256[] memory tokenIds = stakePortfolioByUser[user];

        for (uint256 currentId = 0; currentId < tokenIds.length; currentId++) {
            if (tokenIds[currentId] == 0) {
                continue;
            }
            harvest(tokenIds[currentId]);
        }
    }

    // ADMIN / SETTER FUNCTIONS
    function setNumberOfBlocksPerRewardUnit(uint256 numberOfBlocks)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        numberOfBlocksPerRewardUnit = numberOfBlocks;
    }

    // parameter value must be supplied with 18 zeros.....
    // e.g.: 3 token = setCoinAmountPerRewardUnit(3000000000000000000)
    function setCoinAmountPerRewardUnit(uint256 coinAmount)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        coinAmountPerRewardUnit = coinAmount;
    }

    // same as setCoinAmountPerRewardUnit()
    function setWelcomeBonusAmount(uint256 coinAmount)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        welcomeBonusAmount = coinAmount;
    }

    function setCollectionAddress(address newAddress)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        require(
            newAddress != address(0),
            "SPCC: update to zero address not possible"
        );
        collectionAddress = newAddress;
    }
}
