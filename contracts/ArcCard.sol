// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ArcCard
 * @notice NFT card for Arc Pack Opening dApp — Testnet
 * @dev ERC721 with on-chain rarity metadata
 */
contract ArcCard is ERC721, ERC721URIStorage, Ownable {

    // ─── Enums ────────────────────────────────────────────────────────────────
    enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

    // ─── Structs ──────────────────────────────────────────────────────────────
    struct CardData {
        uint256 cardId;      // template ID (0-29)
        Rarity  rarity;
        uint256 mintedAt;
        string  name;
        string  element;     // CYBER / VOID / PLASMA / NEXUS
    }

    // ─── State ────────────────────────────────────────────────────────────────
    uint256 private _nextTokenId;
    mapping(uint256 => CardData) public cardData;
    mapping(address => uint256[]) private _ownedTokens;

    address public packOpener; // authorized minter

    // ─── Events ───────────────────────────────────────────────────────────────
    event CardMinted(address indexed to, uint256 tokenId, Rarity rarity, string cardName);

    // ─── Card Templates (30 cards across rarities) ───────────────────────────
    string[8]  private _commonNames   = ["Circuit Drone","Static Node","Byte Runner","Grid Walker","Echo Bot","Nano Shard","Pulse Unit","Data Mule"];
    string[8]  private _rareNames     = ["Arc Sentinel","Void Stalker","Plasma Knight","Neon Oracle","Cyber Reaper","Hex Phantom","Qubit Archer","Storm Cipher"];
    string[8]  private _epicNames     = ["Nexus Titan","Dark Protocol","Omega Hacker","Singularity","Entropy God","Binary Wraith","Core Breaker","Null Prophet"];
    string[6]  private _legendaryNames= ["The Arc Genesis","Infinite Loop","Zero Day","The Last Block","Quantum Deity","Chain Breaker"];

    string[4]  private _elements = ["CYBER","VOID","PLASMA","NEXUS"];

    // ─── Constructor ──────────────────────────────────────────────────────────
    constructor() ERC721("ArcCard", "ARCD") Ownable(msg.sender) {}

    // ─── Authorization ────────────────────────────────────────────────────────
    function setPackOpener(address _packOpener) external onlyOwner {
        packOpener = _packOpener;
    }

    modifier onlyMinter() {
        require(
            msg.sender == packOpener || msg.sender == owner(),
            "ArcCard: not authorized minter"
        );
        _;
    }

    // ─── Mint ─────────────────────────────────────────────────────────────────
    /**
     * @notice Mint a card with given rarity (called by PackOpener contract)
     * @param to      recipient
     * @param rarity  0=Common, 1=Rare, 2=Epic, 3=Legendary
     * @param seed    randomness seed for picking card template
     */
    function mintCard(address to, Rarity rarity, uint256 seed)
        external
        onlyMinter
        returns (uint256 tokenId)
    {
        tokenId = _nextTokenId++;

        string memory cardName;
        string memory element = _elements[seed % 4];

        if (rarity == Rarity.COMMON) {
            cardName = _commonNames[seed % 8];
        } else if (rarity == Rarity.RARE) {
            cardName = _rareNames[seed % 8];
        } else if (rarity == Rarity.EPIC) {
            cardName = _epicNames[seed % 8];
        } else {
            cardName = _legendaryNames[seed % 6];
        }

        cardData[tokenId] = CardData({
            cardId:    seed % 30,
            rarity:    rarity,
            mintedAt:  block.timestamp,
            name:      cardName,
            element:   element
        });

        _safeMint(to, tokenId);
        _ownedTokens[to].push(tokenId);

        emit CardMinted(to, tokenId, rarity, cardName);
    }

    // ─── View ─────────────────────────────────────────────────────────────────
    function getOwnedTokens(address owner_) external view returns (uint256[] memory) {
        return _ownedTokens[owner_];
    }

    function getCardData(uint256 tokenId) external view returns (CardData memory) {
        return cardData[tokenId];
    }

    function rarityName(Rarity r) public pure returns (string memory) {
        if (r == Rarity.COMMON)    return "Common";
        if (r == Rarity.RARE)      return "Rare";
        if (r == Rarity.EPIC)      return "Epic";
        return "Legendary";
    }

    // ─── ERC721 overrides ─────────────────────────────────────────────────────
    function tokenURI(uint256 tokenId)
        public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721URIStorage) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
