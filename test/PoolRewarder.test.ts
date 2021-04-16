import { expect, assert } from 'chai'
import { prepare, deploy, getBigNumber } from "./utilities"


describe("PoolRewarder", function() {
  before(async function() {
    await prepare(this, ['ERC20AccessControlMock', 'ERC20Mock', 'ChefV2', 'PoolRewarder'])
  })

  beforeEach(async function() {
    await deploy(this, [
      ['rewardToken', this.ERC20AccessControlMock],
    ])

    await deploy(this, [
      ['chef', this.ChefV2, [this.rewardToken.address]],
      ["rlp0", this.ERC20Mock, ["LP0", "rLP0T", getBigNumber(30)]],
      ["rlp1", this.ERC20Mock, ["LP1", "rLP1T", getBigNumber(20)]],
      ["rlp2", this.ERC20Mock, ["LP2", "rLP2T", getBigNumber(10)]],
    ])

    // Mint to chef for distribution


    // Deploy pool rewarder with pool 2 set as 0 id
    await deploy(this, [
      ['rewarder', this.PoolRewarder, [this.rewardToken.address, this.chef.address]]
    ])

  })

  describe("Add", function() {
    it("Should add pool with pool rewarder", async function() {
      await expect(this.chef.add(20, this.rlp0.address, this.rewarder.address))
        .to.emit(this.chef, "LogPoolAddition")
        .withArgs(0, 20, this.rlp0.address, this.rewarder.address)
    })
  })
})
