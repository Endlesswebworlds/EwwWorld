import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("EwwWorld", () => {
  async function deployContracts() {
    const [deployer, sender, receiver] = await ethers.getSigners();
    const tokenFactory = await ethers.getContractFactory("EwwWorld");
    let contract = await tokenFactory.deploy();
    return { deployer, sender, receiver, contract };
  }

  async function addWorld() {
    let { contract, deployer, receiver } = await loadFixture(deployContracts);
    const backgroundSource = ethers.utils.toUtf8Bytes("ipfshashtft");
    const codeSource = ethers.utils.toUtf8Bytes("if (true) { console.log('hello world') }");
    const data = "{ 'name': 'hello world' }";
    const id = 1;
    await contract.addWorld(id, backgroundSource, codeSource, data);
    return { contract, deployer, data, backgroundSource, codeSource, id, receiver };
  }

  async function addAsset(contract: any, id: any) {
    const assetId = ethers.utils.formatBytes32String("asset1");
    const imageSource = ethers.utils.toUtf8Bytes("ipfshash3tft");
    const codeSource = ethers.utils.toUtf8Bytes("console.log('asset added')");
    const data = "{ 'name': 'asset1' }";
    await contract.addAsset(id, assetId, imageSource, codeSource, data);
    return { assetId, imageSource, codeSource, data };
  }

  function mapToStr(obj: any) {
    return ethers.utils.toUtf8String(obj);
  }

  it('should add a new world', async () => {
    const { contract, id } = await addWorld();
    expect(await contract.worldCount()).to.eq(1);
    expect(await contract.isEditor(id)).to.eq(true);
  });

  it('should update a world', async () => {
    const { contract, id } = await addWorld();
    const newBackgroundSource = ethers.utils.toUtf8Bytes("ipfshash2tft");
    const newCodeSource = ethers.utils.toUtf8Bytes("if (true) { console.log('world updated') }");
    await contract.updateWorld(id, newBackgroundSource, newCodeSource);
    const [returnedBackgroundSource, returnedCodeSource] = await contract.getWorld(id);
    expect(mapToStr(returnedBackgroundSource)).to.eq(mapToStr(newBackgroundSource));
    expect(mapToStr(returnedCodeSource)).to.eq(mapToStr(newCodeSource));
  });

  it('should update the version of a world', async () => {
    const { contract, id } = await addWorld();
    await contract.updateWorldVersion(id);
    expect(await contract.versionOfWorld(id)).to.eq(1);
  });

  it('should add an editor to a world', async () => {
    const { contract, id, receiver } = await addWorld();
    await contract.addEditor(id, receiver.getAddress());
    expect(await contract.connect(receiver).isEditor(id)).to.eq(true);
  });

  it('should remove an editor from a world', async () => {
    const { contract, id, receiver } = await addWorld();
    await contract.addEditor(id, receiver.getAddress());
    expect(await contract.connect(receiver).isEditor(id)).to.eq(true);
    await contract.removeEditor(id, receiver.getAddress());
    expect(await contract.connect(receiver).isEditor(id)).to.eq(false);
  });

  it('should add an asset to a world', async () => {
    const { contract, id } = await addWorld();
    await addAsset(contract, id);
    expect(await contract.assetCount(id)).to.eq(1);
  });

  it('should get an asset', async () => {
    const { contract, id } = await addWorld();
    const { assetId, imageSource, codeSource, data } = await addAsset(contract, id);
    const returnedAsset = await contract.assets(id, assetId);
    expect(mapToStr(returnedAsset.imageSource)).to.eq(mapToStr(imageSource));
    expect(mapToStr(returnedAsset.codeSource)).to.eq(mapToStr(codeSource));
    expect(returnedAsset.data).to.eq(data);
  });

  it('should remove an asset', async () => {
    const { contract, id } = await addWorld();
    const { assetId } = await addAsset(contract, id);
    await contract.deleteAsset(id, assetId);
    expect(await contract.assetCount(id)).to.eq(0);
  });

  it("should add an editor to the world", async () => {
    const { contract, id, receiver } = await addWorld();
    await contract.addEditor(id, receiver.address);
    const expected = await contract.connect(receiver.address).isEditor(id);
    expect(expected).to.be.true;
  });

  it("should remove an editor of an world", async () => {
    const { contract, id, receiver } = await addWorld();
    await contract.addEditor(id, receiver.address);
    const expected = await contract.connect(receiver.address).isEditor(id);
    expect(expected).to.be.true;

    await contract.removeEditor(id, receiver.address);
    const expected2 = await contract.connect(receiver.address).isEditor(id);
    expect(expected2).to.be.false;
  });
});
