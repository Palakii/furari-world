// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ArcLeaderboard
 * @notice On-chain leaderboard — tracks top collectors by points
 */
contract ArcLeaderboard is Ownable {

    struct Entry {
        address user;
        uint256 points;
        uint256 packsOpened;
        string  nickname;
    }

    mapping(address => Entry) public entries;
    mapping(address => bool)  public registered;
    address[] public users;

    address public packOpener; // syncs points from PackOpener

    event NicknameSet(address indexed user, string nickname);
    event PointsSynced(address indexed user, uint256 points);

    constructor() Ownable(msg.sender) {}

    function setPackOpener(address _packOpener) external onlyOwner {
        packOpener = _packOpener;
    }

    /// @notice Register with a nickname
    function register(string calldata nickname) external {
        require(bytes(nickname).length > 0 && bytes(nickname).length <= 20, "Invalid nickname");
        if (!registered[msg.sender]) {
            registered[msg.sender] = true;
            users.push(msg.sender);
        }
        entries[msg.sender].user     = msg.sender;
        entries[msg.sender].nickname = nickname;
        emit NicknameSet(msg.sender, nickname);
    }

    /// @notice Sync points from PackOpener (called by user or authorized)
    function syncPoints(address user, uint256 pts, uint256 packs) external {
        require(msg.sender == packOpener || msg.sender == owner(), "Not authorized");
        if (!registered[user]) {
            registered[user] = true;
            users.push(user);
            entries[user].user = user;
        }
        entries[user].points      = pts;
        entries[user].packsOpened = packs;
        emit PointsSynced(user, pts);
    }

    /// @notice Get top N users sorted by points (simple, gas-heavy — ok for testnet)
    function getTopN(uint256 n) external view returns (Entry[] memory top) {
        uint256 total = users.length;
        if (n > total) n = total;

        // Copy all entries
        Entry[] memory all = new Entry[](total);
        for (uint256 i = 0; i < total; i++) {
            all[i] = entries[users[i]];
        }

        // Bubble sort top N (fine for small leaderboards on testnet)
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = i + 1; j < total; j++) {
                if (all[j].points > all[i].points) {
                    Entry memory tmp = all[i];
                    all[i] = all[j];
                    all[j] = tmp;
                }
            }
        }

        top = new Entry[](n);
        for (uint256 i = 0; i < n; i++) {
            top[i] = all[i];
        }
    }

    function getTotalUsers() external view returns (uint256) {
        return users.length;
    }
}
