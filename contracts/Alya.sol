// SPDX-License-Identifier: MIT
// Creator: dev.dev

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

error CannotSetZeroAddress();

contract AlyaValley is ERC721A, Ownable {
    using Address for address;

    string public baseURI = "";
    string public suffixURI = ".json";

    bytes32 whiteListProof;

    uint256 public maxSupply;
    uint8 public mintPhase;

    bool public revealed;

    uint256 public mintAllocationWL = 2;
    uint256 public mintAllocationPublic = 5;

    uint256 public priceWL = .25 ether;
    uint256 public pricePublic = .3 ether;

    constructor(string memory _initBaseURI, bytes32 _wl)
        ERC721A("Alya", "ALYA")
    {
        baseURI = _initBaseURI;
        whiteListProof = _wl;

        // Max supply set to 8888 by default
        maxSupply = 8888;
    }

    modifier mintCompliance(uint256 _mintCount, uint8 _mintType) {
        require(msg.sender == tx.origin, "EOA only");
        require(
            (totalSupply() + _mintCount) <= maxSupply,
            "Max supply exceeded"
        );

        require(mintActive(_mintType), "Mint phase not active");
        _;
    }

    function mintActive(uint8 mintType) public view returns (bool active) {
        // only WL can mint
        if (mintPhase == 1) return mintType == 1;
        // public mint, everyone can mint
        if (mintPhase == 2) return true;
        return false;
    }

    /**
     * @dev Mint function for WLs
     * Mint Type for wlMint is 2
     */
    function wlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_mintAmount, 1)
    {
        address _owner = msg.sender;
        require(
            _numberMinted(_owner) + _mintAmount < mintAllocationWL,
            "Max minted"
        );
        require(
            MerkleProof.verify(
                _merkleProof,
                whiteListProof,
                keccak256(abi.encodePacked(_owner))
            ),
            "Invalid Merkle Proof"
        );

        _mint(_owner, _mintAmount);
    }

    function mint(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount, 2)
    {
        address _owner = msg.sender;
        require(
            _numberMinted(_owner) + _mintAmount < mintAllocationPublic,
            "Max minted"
        );

        _mint(_owner, _mintAmount);
    }

    /**
     * @dev Withdraw funds to treasuryAddress (onlyOwner)
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), (address(this).balance * 80) / 100);

        Address.sendValue(
            payable(0x91b6DFa9Fdc28d3C8064830F17D5768B1d082EFf),
            (address(this).balance * 5) / 100
        );
        Address.sendValue(
            payable(0x91b6DFa9Fdc28d3C8064830F17D5768B1d082EFf),
            (address(this).balance * 5) / 100
        );
    }

    /**
     * @dev sets a state of mint (onlyOwner)
     *
     * Requirements:
     * - `_state` should be in: [0, 1, 2]
     * - 0 - mint not active, default
     * - 1 - sets mint to WL only
     * - 2 - sets mint to public(FFA)
     */
    function setSale(uint8 _state) public onlyOwner {
        mintPhase = _state;
    }

    /**
     * @dev Sets a Merkle proof (onlyOwner)
     */
    function setMerkle(bytes32 _merkleRoot) external onlyOwner {
        whiteListProof = _merkleRoot;
    }

    /**
     * @dev Get the number of tokens an address has minted
     */
    function getMinted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    /**
     * @dev Reveal collection URIs (onlyOwner)
     */
    function setRevealed() public onlyOwner {
        revealed = true;
    }

    /**
     * @dev Override to use hidden metadata and suffix in case we need it in the future
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!revealed) return baseURI;

        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), suffixURI)
                )
                : "";
    }

    /**
     * @dev sets a price for a sale type (onlyOwner)
     * Requirements:
     * - `_state` should be in: [1, 2]
     * - 1 - WL price
     * - 2 - public price
     */
    function setPrice(uint8 _saleId, uint256 _price) external onlyOwner {
        if (_saleId == 1) {
            priceWL = _price;
        }
        if (_saleId == 2) {
            pricePublic = _price;
        }
    }

    /**
     * @dev Change max supply for collection (onlyOwner)
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
}
