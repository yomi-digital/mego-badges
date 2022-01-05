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
    mapping(uint256 => string) public _idToEventMetadata;
    mapping(string => uint256) public _metadataToEventId;
    mapping(uint256 => address) public _creators;
    mapping(address => uint256[]) public _created;
    mapping(address => uint256[]) public _received;
    mapping(uint256 => uint256) internal _endTimestamp;
    mapping(uint256 => uint256) internal _startTimestamp;
    mapping(string => mapping(uint256 => bool)) internal _nameBalances;
    mapping(uint256 => mapping(address => bool)) internal _addressWhitelist;
    mapping(uint256 => mapping(address => bool)) internal _addressBlacklist;
    mapping(uint256 => mapping(string => bool)) internal _nameWhitelist;
    mapping(uint256 => mapping(string => bool)) internal _nameBlacklist;
    uint256 nonce = 0;

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
     * Admin functions to fix base uri if needed
     */
    function setURI(string memory newuri) public onlyOwner {
        metadata_uri = newuri;
        _setURI(newuri);
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
     * Public function to return the address of a specific name
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

    function prepare(
        uint256 start_timestamp,
        uint256 end_timestamp,
        string memory metadata
    ) public returns (uint256) {
        require(
            block.timestamp < start_timestamp,
            "BadgME: Start time must be in the future"
        );
        require(
            _metadataToEventId[metadata] == 0,
            "BadgeME: Trying to push same event to another id"
        );
        uint256 id = uint256(
            keccak256(
                abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))
            )
        );
        while (_startTimestamp[id] > 0) {
            nonce += 1;
            id = uint256(
                keccak256(
                    abi.encodePacked(
                        nonce,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            );
        }
        _idToEventMetadata[id] = metadata;
        _metadataToEventId[metadata] = id;
        _startTimestamp[id] = start_timestamp;
        _endTimestamp[id] = end_timestamp;
        _creators[id] = msg.sender;
        _created[msg.sender].push(id);
        return id;
    }

    function created(address _creator)
        public
        view
        returns (uint256[] memory createdTokens)
    {
        return _created[_creator];
    }

    function received(address _receiver)
        public
        view
        returns (uint256[] memory receivedTokens)
    {
        return _received[_receiver];
    }

    function tokenCID(uint256 id)
        public
        view
        returns (string memory)
    {
        return _idToEventMetadata[id];
    }

    function mint(uint256 id, uint256 amount) public {
        require(_startTimestamp[id] > 0, "BadgeME: This event doesn't exists");
        require(
            _creators[id] == msg.sender,
            "BadgeME: Can't mint tokens you haven't created"
        );
        require(
            block.timestamp < _endTimestamp[id],
            "BadgeME: Can't mint after the end of the event"
        );
        _mint(msg.sender, id, amount, bytes(""));
    }

    function claim(uint256 id, string memory name) public {
        require(_startTimestamp[id] > 0, "BadgeME: This event doesn't exists");
        require(
            block.timestamp < _endTimestamp[id],
            "BadgeME: Can't claim after the end of the event"
        );
        address to = msg.sender;
        if (bytes(name).length > 0) {
            to = getAddress(name);
            require(
                _nameBalances[name][id] == false,
                "BadgeME: Name received badge yet"
            );
            require(_nameBlacklist[id][name] == false, "Name is in blacklist");
            require(_nameWhitelist[id][name] == true, "Name is in blacklist");
            _nameBalances[name][id] = true;
        }
        require(
            ERC1155.balanceOf(to, id) == 0,
            "BadgeME: Can't send more than one NFT to same account"
        );
        require(_addressBlacklist[id][to] == false, "Address is in blacklist");
        require(_addressWhitelist[id][to] == true, "Address is in blacklist");
        _received[to].push(id);
        _mint(to, id, 1, bytes(""));
    }

    function manageAddressWhitelist(
        uint256 id,
        address[] memory addresses,
        bool state,
        uint256 list
    ) public {
        require(
            _creators[id] == msg.sender,
            "BadgeME: Can't manage whitelist, not the owner"
        );
        require(_startTimestamp[id] > 0, "BadgeME: This event doesn't exists");
        require(
            block.timestamp < _endTimestamp[id],
            "BadgeME: Can't manage after the end of the event"
        );
        if (list == 0) {
            for (uint256 i = 0; i < addresses.length; i++) {
                _addressWhitelist[id][addresses[i]] = state;
            }
        } else {
            for (uint256 i = 0; i < addresses.length; i++) {
                _addressBlacklist[id][addresses[i]] = state;
            }
        }
    }

    function manageNameWhitelist(
        uint256 id,
        string[] memory names,
        bool state,
        uint256 list
    ) public {
        require(
            _creators[id] == msg.sender,
            "BadgeME: Can't manage whitelist, not the owner"
        );
        require(_startTimestamp[id] > 0, "BadgeME: This event doesn't exists");
        require(
            block.timestamp < _endTimestamp[id],
            "BadgeME: Can't manage after the end of the event"
        );
        if (list == 0) {
            for (uint256 i = 0; i < names.length; i++) {
                _nameWhitelist[id][names[i]] = state;
            }
        } else {
            for (uint256 i = 0; i < names.length; i++) {
                _nameBlacklist[id][names[i]] = state;
            }
        }
    }

    /**
     * Function to get the creator of a specific event
     */
    function creatorOfEvent(uint256 tknId) public view returns (address) {
        return _creators[tknId];
    }

    /**
     * Function to get the whitelist status
     */
    function isInAddressWhitelist(uint256 id, address who)
        public
        view
        returns (bool)
    {
        return _addressWhitelist[id][who];
    }

    function isInNameWhitelist(uint256 name, string memory who)
        public
        view
        returns (bool)
    {
        return _nameWhitelist[name][who];
    }

    /**
     * Function to get the blacklist status
     */
    function isInAddressBlacklist(uint256 id, address who)
        public
        view
        returns (bool)
    {
        return _addressBlacklist[id][who];
    }

    function isInNameBlacklist(uint256 name, string memory who)
        public
        view
        returns (bool)
    {
        return _nameBlacklist[name][who];
    }

    /**
     * Function to get the balance of a specific event for required name
     */
    function hasBadge(string memory name, uint256 id)
        public
        view
        returns (bool)
    {
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
        require(
            to != address(0) || bytes(name).length > 0,
            "BadgeME: Must specify address or name"
        );
        require(
            ERC1155.balanceOf(msg.sender, id) > 0,
            "BadgeME: Must own that token"
        );
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
            if (bytes(name).length > 0) {
                to = getAddress(name);
                require(
                    _nameBalances[name][id] == false,
                    "BadgeME: Name received badge yet"
                );
                require(
                    _nameBlacklist[id][name] == false,
                    "Name is in blacklist"
                );
                _nameBalances[name][id] = true;
            }
            require(
                ERC1155.balanceOf(to, id) == 0,
                "BadgeME: Can't send more than one NFT to same account"
            );
            require(
                _addressBlacklist[id][to] == false,
                "Address is in blacklist"
            );
            _received[to].push(id);
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
        require(1 < 0, "BadgeME: Native transfers are disabled");
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal pure override {
        require(1 < 0, "BadgeME: Native transfers are disabled");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public pure override {
        require(1 < 0, "BadgeME: Native transfers are disabled");
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal pure override {
        require(1 < 0, "BadgeME: Native transfers are disabled");
    }
}
