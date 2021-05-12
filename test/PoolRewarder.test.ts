import { expect } from 'chai'
import { prepare, deploy, getBigNumber, advanceBlock } from "./utilities"


describe("PoolRewarder", function() {
  before(async function() {
    await prepare(this, ['ERC20AccessControlMock', 'ERC20Mock', 'ChefV2', 'PoolRewarder'])
  })

  beforeEach(async function() {
    // Deploy the reward token
    await deploy(this, [
      ['rewardToken', this.ERC20AccessControlMock],
    ])

    // Deploy base liquidity mining contract (chef) and mock LP tokens to
    // deposit into farms
    await deploy(this, [
      ['chef', this.ChefV2, [this.rewardToken.address]],
      ["rlp0", this.ERC20Mock, ["LP0", "rLP0T", getBigNumber(10)]],
      ["rlp1", this.ERC20Mock, ["LP1", "rLP1T", getBigNumber(10)]],
      ["rlp2", this.ERC20Mock, ["LP2", "rLP2T", getBigNumber(10)]],
    ])

    // Deploy pool rewarder to be called on each deposit/withdraw/harvest
    // on chef
    await deploy(this, [
      ['rewarder', this.PoolRewarder, [this.rewardToken.address, this.chef.address]]
    ])

    // Mint to chef for liquidity mining distribution
    await this.rewardToken.mint(this.chef.address, getBigNumber(1000000))

    // Add LP pools to be rewarded by chef
    await this.chef.add(10, this.rlp0.address, this.rewarder.address)
    await this.chef.add(10, this.rlp1.address, this.rewarder.address)
    await this.chef.add(20, this.rlp2.address, this.rewarder.address) // pool2
  })

  describe("Set", function() {
    it("Should set alloc points in pool rewarder", async function() {
      await this.rewarder.set(2, 10)
      expect(await this.rewarder.poolAllocPoint(2)).to.be.equal(10)
      expect(await this.rewarder.totalAllocPoint()).to.be.equal(10)
    })

    it("Should allow alloc points for multiple pools", async function() {
      await this.rewarder.set(2, 20)
      await this.rewarder.set(1, 10)
      expect(await this.rewarder.totalAllocPoint()).to.be.equal(30)
      expect(await this.rewarder.poolAllocPoint(2)).to.be.equal(20)
      expect(await this.rewarder.poolAllocPoint(1)).to.be.equal(10)
    })

    it("Update allocation points in pool rewarder", async function() {
      await this.rewarder.set(2, 20)
      await this.rewarder.set(1, 10)
      expect(await this.rewarder.totalAllocPoint()).to.be.equal(30)
      await this.rewarder.set(1, 15)
      expect(await this.rewarder.poolAllocPoint(1)).to.be.equal(15)
      expect(await this.rewarder.poolAllocPoint(2)).to.be.equal(20)
      expect(await this.rewarder.totalAllocPoint()).to.be.equal(35)
    })
  })

  describe("onSushiReward", function() {
    it("Should give back correct amount of additional trading fee rewards with One LP", async function() {
      await this.rewardToken.mint(this.rewarder.address, getBigNumber(1))
      await this.rewarder.set(0, 20)
      expect(await this.rewarder.poolAllocPoint(0)).to.be.equal(20)
      expect(await this.rewarder.totalAllocPoint()).to.be.equal(20)
      await this.rlp0.approve(this.chef.address, getBigNumber(10))
      expect(await this.chef.lpToken(0)).to.be.equal(this.rlp0.address)
      let log1 = await this.chef.deposit(0, getBigNumber(5), this.alice.address)
      await advanceBlock();
      let expectedUserLpShares = getBigNumber(5);
      let expectedTotalLpShares = getBigNumber(5);
      let expectedRewardsInPoolRewarder = getBigNumber(1);
      let expectedWeightForRewardPool = 20 / 20;
      let expectedPoolRewards = expectedRewardsInPoolRewarder.mul(expectedUserLpShares / expectedTotalLpShares).mul(expectedWeightForRewardPool);
      let log2 = await this.chef.harvest(0, this.alice.address);
      let expectedSushi = getBigNumber(100).mul(log2.blockNumber - log1.blockNumber).mul(getBigNumber(10)).div(getBigNumber(40));
      expect(await this.rewardToken.balanceOf(this.alice.address)).to.be.equal(expectedPoolRewards.add(expectedSushi));
    })

    it("Should give back correct amount of additional trading fee rewards with multiple LPs", async function() {
      await this.rewardToken.mint(this.rewarder.address, getBigNumber(5))
      await this.rewarder.set(0, 20)
      await this.rewarder.set(1, 20)
      expect(await this.rewarder.poolAllocPoint(0)).to.be.equal(20)
      expect(await this.rewarder.totalAllocPoint()).to.be.equal(40)
      await this.rlp0.approve(this.chef.address, getBigNumber(10))
      expect(await this.chef.lpToken(0)).to.be.equal(this.rlp0.address)
      let log1 = await this.chef.deposit(0, getBigNumber(10), this.alice.address)
      await advanceBlock()
      let expectedUserLpShares = getBigNumber(10);
      let expectedTotalLpShares = getBigNumber(10);
      let expectedRewardsInPoolRewarder = getBigNumber(5);
      let expectedWeightForRewardPool = 20;
      let expectedPoolRewards = expectedRewardsInPoolRewarder.mul(expectedUserLpShares).div(expectedTotalLpShares).mul(expectedWeightForRewardPool).div(40);
      let log2 = await this.chef.harvest(0, this.alice.address);
      let expectedSushi = getBigNumber(100).mul(log2.blockNumber - log1.blockNumber).mul(getBigNumber(10)).div(getBigNumber(40));
      expect(await this.rewardToken.balanceOf(this.alice.address)).to.be.equal(expectedPoolRewards.add(expectedSushi));
    })
})

  describe("pendingTokens", function() {

  })
})
