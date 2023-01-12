// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@ensdomains/ens-contracts/contracts/ethregistrar/StringUtils.sol";

contract EwwWorld {
    struct World {
        bytes backgroundSource;
        bytes codeSource;
        string data;
    }

    // AssetId is a hash of the asset's map position(x,y,z) + asset type (1=Floor,2=Object)
    struct Asset {
        bytes imageSource;
        bytes codeSource;
        string data;
    }

    uint256 public worldCount;
    mapping(uint256 => World) public worlds; // worlds[worldId] = World
    mapping(uint256 => uint256) public worldVersion; // worldVersion[worldId] = version
    mapping(uint256 => uint256) public assetCount; // assetCount[worldId] = assetCount
    mapping(uint256 => mapping(bytes32 => Asset)) public assets; // assets[worldId][assetId] = Asset
    mapping(uint256 => bytes32[]) public assetIds; // assetIds[worldId] = [assetId1, assetId2, ...]
    mapping(uint256 => mapping(address => bool)) public editors; // editors[worldId][editorAddress]

    function addWorld(
        uint256 worldId,
        bytes memory _backgroundSource,
        bytes memory _codeSource,
        string memory _data
    ) public payable {
        require(editors[worldId][msg.sender] != true, "World already exists.");
        worlds[worldId] = World(_backgroundSource, _codeSource, _data);
        editors[worldId][msg.sender] = true;
        worldCount++;
        worldVersion[worldId] = 0;
    }

    function getWorld(uint256 _worldId) public view returns (bytes memory, bytes memory) {
        World memory world = worlds[_worldId];
        return (world.backgroundSource, world.codeSource);
    }

    function updateWorld(
        uint256 _worldId,
        bytes memory _backgroundSource,
        bytes memory _codeSource
    ) public payable {
        // require(isEditor(_worldId), "Sender is not an editor of this world.");
        World storage world = worlds[_worldId];
        world.backgroundSource = _backgroundSource;
        world.codeSource = _codeSource;
    }

    function updateWorldVersion(uint256 _worldId) public payable {
        require(isEditor(_worldId), "Sender is not an editor of this world.");
        worldVersion[_worldId] += 1;
    }

    function versionOfWorld(uint256 id) public view returns (uint256) {
        return worldVersion[id];
    }

    function addEditor(uint256 _worldId, address _editor) public payable {
        require(isEditor(_worldId), "Already an editor of this world.");
        editors[_worldId][_editor] = true;
    }

    function removeEditor(uint256 _worldId, address _editor) public payable {
        require(isEditor(_worldId), "Editor is not an editor of this world.");
        delete editors[_worldId][_editor];
    }

    function addAsset(
        uint256 _worldId,
        bytes32 _assetId,
        bytes memory _imageSource,
        bytes memory _codeSource,
        string memory _data
    ) public payable {
        require(isEditor(_worldId), "Sender is not an editor of this world.");
        assets[_worldId][_assetId] = Asset(_imageSource, _codeSource, _data);
        assetCount[_worldId]++;
        assetIds[_worldId].push(_assetId);
    }

    function bulkAddAsset(
        uint256 _worldId,
        bytes32[] memory _assetIds,
        bytes[] memory _imageSources,
        bytes[] memory _codeSources,
        string[] memory _datas
    ) public payable {
        require(isEditor(_worldId), "Sender is not an editor of this world.");
        require(
            _assetIds.length == _imageSources.length &&
                _assetIds.length == _codeSources.length &&
                _assetIds.length == _datas.length,
            "Mismatch in length of input arrays."
        );

        for (uint256 i = 0; i < _assetIds.length; i++) {
            assets[_worldId][_assetIds[i]] = Asset(_imageSources[i], _codeSources[i], _datas[i]);
            assetCount[_worldId]++;
            assetIds[_worldId].push(_assetIds[i]);
        }
    }

    function updateAsset(
        uint256 _worldId,
        bytes32 _assetId,
        bytes memory _imageSource,
        bytes memory _codeSource,
        string memory _data
    ) public payable {
        require(isEditor(_worldId), "Sender is not an editor of this world.");
        Asset storage asset = assets[_worldId][_assetId];
        asset.imageSource = _imageSource;
        asset.codeSource = _codeSource;
        asset.data = _data;
    }

    function bulkUpdateAsset(
        uint256 _worldId,
        bytes32[] memory _assetIds,
        bytes[] memory _imageSources,
        bytes[] memory _codeSources,
        string[] memory _datas
    ) public payable {
        require(isEditor(_worldId), "Sender is not an editor of this world.");
        require(
            _assetIds.length == _imageSources.length &&
                _assetIds.length == _codeSources.length &&
                _assetIds.length == _datas.length,
            "Mismatch in length of input arrays."
        );

        for (uint256 i = 0; i < _assetIds.length; i++) {
            Asset storage asset = assets[_worldId][_assetIds[i]];
            asset.imageSource = _imageSources[i];
            asset.codeSource = _codeSources[i];
            asset.data = _datas[i];
        }
    }

    function deleteAsset(uint256 _worldId, bytes32 _assetId) public payable {
        require(isEditor(_worldId), "Sender is not an editor of this world.");
        delete assets[_worldId][_assetId];
        assetCount[_worldId]--;

        // Remove the assetId from the assetIds array
        for (uint256 i = 0; i < assetIds[_worldId].length; i++) {
            if (assetIds[_worldId][i] == _assetId) {
                delete assetIds[_worldId][i];
                break;
            }
        }
    }

    function bulkDeleteAsset(uint256 _worldId, bytes32[] memory _assetIds) public payable {
        require(isEditor(_worldId), "Sender is not an editor of this world.");

        for (uint256 i = 0; i < _assetIds.length; i++) {
            bytes32 _assetId = _assetIds[i];
            delete assets[_worldId][_assetId];
            assetCount[_worldId]--;

            // Remove the assetId from the assetIds array
            for (uint256 j = 0; j < assetIds[_worldId].length; j++) {
                if (assetIds[_worldId][j] == _assetId) {
                    delete assetIds[_worldId][j];
                    break;
                }
            }
        }
    }

    function getAsset(uint256 _worldId, bytes32 _assetId)
        public
        view
        returns (
            bytes memory,
            bytes memory,
            string memory
        )
    {
        Asset memory asset = assets[_worldId][_assetId];
        return (asset.imageSource, asset.codeSource, asset.data);
    }

    function assetsOfWorld(uint256 _worldId) public view returns (Asset[] memory) {
        bytes32[] memory foundAssetIds = assetIds[_worldId];
        Asset[] memory result = new Asset[](assetCount[_worldId]);
        for (uint256 i = 0; i < foundAssetIds.length; i++) {
            result[i] = assets[_worldId][foundAssetIds[i]];
        }
        return result;
    }

    function isEditor(uint256 _worldId) public view returns (bool) {
        address sender = msg.sender;
        if (editors[_worldId][sender] == true) return true;
        else return false;
    }
}
