// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ─────────────────────────────────────────────
//  Minimal ERC-20 interface (เฉพาะที่ใช้จริง)
// ─────────────────────────────────────────────
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// ─────────────────────────────────────────────
//  PackOpener Contract
//  - รับ USDC จากผู้ใช้
//  - ส่ง USDC ตรงไปยัง treasury wallet
//  - emit event เพื่อให้ frontend รู้ว่าจ่ายสำเร็จ
// ─────────────────────────────────────────────
contract PackOpener {

    // ── CONSTANTS ──────────────────────────────────────────────────────────────
    // USDC บน Arc Testnet (6 decimals)
    address public constant USDC = 0x3600000000000000000000000000000000000000;

    // ราคาแต่ละ pack (หน่วย: USDC มี 6 decimals)
    // 1 USDC = 1_000_000 | 3 USDC = 3_000_000 | 5 USDC = 5_000_000
    uint256[3] public PACK_PRICES = [1_000_000, 3_000_000, 5_000_000];

    // จำนวนการ์ดแต่ละ pack
    uint8[3] public PACK_SIZES = [3, 5, 7];

    // ── STATE ──────────────────────────────────────────────────────────────────
    address public owner;      // คนที่ deploy contract
    address public treasury;   // wallet ที่รับเงิน USDC

    bool public paused;        // ปิด/เปิด การเปิด pack

    // นับจำนวน pack ที่เปิดไปทั้งหมด (ใช้เป็น unique id)
    uint256 public totalPacksOpened;

    // ── EVENTS ─────────────────────────────────────────────────────────────────
    // frontend ฟัง event นี้เพื่อรู้ว่าจ่ายสำเร็จ → เริ่ม reveal
    event PackOpened(
        address indexed buyer,   // wallet ผู้ซื้อ
        uint8 indexed packType,  // 0=Pulse, 1=Core, 2=Nexus
        uint256 packId,          // unique id ของ pack นี้
        uint256 amountPaid       // จำนวน USDC ที่จ่าย (6 decimals)
    );

    event TreasuryChanged(address indexed oldTreasury, address indexed newTreasury);
    event Paused(bool isPaused);

    // ── MODIFIERS ──────────────────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // ── CONSTRUCTOR ────────────────────────────────────────────────────────────
    // ตอน deploy ใส่ treasury wallet address ของคุณ
    constructor(address _treasury) {
        require(_treasury != address(0), "Invalid treasury");
        owner    = msg.sender;
        treasury = _treasury;
    }

    // ── MAIN FUNCTION: openPack ────────────────────────────────────────────────
    //
    //  ขั้นตอน (frontend ทำ 2 TX):
    //  1. approve(PackOpener_address, price)  ← TX แรก (ผู้ใช้อนุญาต)
    //  2. openPack(packType)                  ← TX นี้ (ดึงเงิน + emit event)
    //
    //  packType: 0 = Pulse (1 USDC), 1 = Core (3 USDC), 2 = Nexus (5 USDC)
    // ──────────────────────────────────────────────────────────────────────────
    function openPack(uint8 packType) external notPaused returns (uint256 packId) {
        require(packType < 3, "Invalid pack type");

        uint256 price = PACK_PRICES[packType];

        // ดึง USDC จาก wallet ผู้ใช้ → treasury โดยตรง
        // (ต้อง approve ก่อน)
        bool ok = IERC20(USDC).transferFrom(msg.sender, treasury, price);
        require(ok, "USDC transfer failed");

        // นับ pack id
        totalPacksOpened++;
        packId = totalPacksOpened;

        // emit event → frontend รับแล้ว reveal การ์ด
        emit PackOpened(msg.sender, packType, packId, price);
    }

    // ── ADMIN FUNCTIONS ────────────────────────────────────────────────────────

    // เปลี่ยน treasury wallet
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid treasury");
        emit TreasuryChanged(treasury, _treasury);
        treasury = _treasury;
    }

    // ปิด/เปิด การขาย (กรณีฉุกเฉิน)
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    // โอน ownership ไปคนอื่น
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    // ── VIEW FUNCTIONS ─────────────────────────────────────────────────────────

    // ดู USDC balance ของ contract (ปกติจะ 0 เพราะส่งตรง treasury)
    function contractBalance() external view returns (uint256) {
        return IERC20(USDC).balanceOf(address(this));
    }

    // ดูราคา pack (คืนค่า 6 decimals)
    function getPackPrice(uint8 packType) external view returns (uint256) {
        require(packType < 3, "Invalid pack type");
        return PACK_PRICES[packType];
    }
}
