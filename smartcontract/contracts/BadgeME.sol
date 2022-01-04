// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IME.sol";

/**
 * @title BadgeME
 * BadgeME - Extending PolygonME with Badges
 */
contract BadgeME is ERC1155, Ownable {
    IME private _me;
    string metadata_uri;
    mapping(uint256 => address) public _creators;
    mapping(uint256 => uint256) public _endTimestamp;
    mapping(uint256 => uint256) public _startTimestamp;
    mapping(string => mapping(uint256 => bool)) public _nameBalances;

    constructor(address PolygonME)
        ERC1155("https://badges.polygonme.xyz/{id}.json")
    {
        _me = IME(PolygonME);
        metadata_uri = "https://badges.polygonme.xyz/{id}.json";
    }

    /**
     * Admin functions to fix base address if needed
     */
    function fixME(address PolygonME) public onlyOwner {
        _me = IME(PolygonME);
    }

    /**
     * Internal function to return the tokenId for a specific name
     */
    function returnNameId(string memory _name, string memory _gate)
        internal
        view
        returns (uint256)
    {
        uint256 tknId = _me._nameToTokenId(
            string(abi.encodePacked(_name, ".", _gate))
        );
        require(tknId > 0, "BadgeME: This name doesn't exists.");
        return tknId;
    }

    /**
     * Internal function to return the tokenId for a specific name
     */
    function getAddress(string memory _name) public view returns (address) {
        uint256 tknId = _me._nameToTokenId(_name);
        if (tknId > 0) {
            address settedAddress = _me.getAddressByName(_name);
            if (settedAddress != address(0)) {
                return settedAddress;
            } else {
                address owner = _me.ownerOf(tknId);
                return owner;
            }
        } else {
            return address(0);
        }
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data,
        uint256 start_timestamp,
        uint256 end_timestamp
    ) public {
        require(
            block.timestamp < start_timestamp,
            "BadgME: Can't mint token in the past"
        );
        // Be sure that starting and ending timestamps can't be changed after issuance.
        if (_startTimestamp[id] == 0) {
            _startTimestamp[id] = start_timestamp;
            _endTimestamp[id] = end_timestamp;
            _creators[id] = msg.sender;
        } else {
            require(
                _creators[id] == msg.sender,
                "BadgeME: Can't mint tokens you haven't created"
            );
            require(
                block.timestamp < _endTimestamp[id],
                "BadgeME: Can't mint after the end of the event"
            );
        }
        _mint(account, id, amount, data);
    }

    /**
     * Function to get the creator of a specific event
     */
    function creatorOfEvent(uint256 tknId) public view returns (address) {
        return _creators[tknId];
    }
    /**
     * Function to get the balance of a specific event for required name
     */
    function hasBadge(string memory name, uint256 id) public view returns (bool) {
        require(getAddress(name) != address(0), "BadgeME: Name doesn't exists");
        return _nameBalances[name][id];
    }

    function transferBadge(
        address to,
        string memory name,
        uint256 id
    ) public {
        require(
            creatorOfEvent(id) == msg.sender,
            "BadgeME: Only creator can transfer tokens"
        );
        require(to != address(0) || bytes(name).length > 0, "BadgeME: Must specify address or name");
        require(ERC1155.balanceOf(msg.sender, id) > 0, "BadgeME: Must own that token");
        // Require event started
        require(
            block.timestamp >= _startTimestamp[id],
            "BadgeME: Can't move before beginning"
        );
        // Burn all tokens if try to transfer after deadline
        if (block.timestamp >= _endTimestamp[id]) {
            uint256 balance = ERC1155.balanceOf(msg.sender, id);
            return ERC1155._burn(msg.sender, id, balance);
        } else {
            // Check if transaction has name or address
            if(bytes(name).length > 0){
                to = getAddress(name);
                require(_nameBalances[name][id] == false, "BadgeME: Name received badge yet");
            }
            require(
                ERC1155.balanceOf(to, id) == 0,
                "BadgeME: Can't send more than one NFT to same account"
            );
            _nameBalances[name][id] = true;
            return ERC1155._safeTransferFrom(msg.sender, to, id, 1, bytes(""));
        }
    }

    // Overriding native transfer functions

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public pure override {
        require(
            1 < 0,
            "BadgeME: Native transfers are disabled"
        );
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal pure override {
        require(
            1 < 0,
            "BadgeME: Native transfers are disabled"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public pure override {
        require(
            1 < 0,
            "BadgeME: Native transfers are disabled"
        );
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal pure override {
        require(
            1 < 0,
            "BadgeME: Native transfers are disabled"
        );
    }
}
