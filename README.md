# staking (WIP)

Similar to Indexed Finance's [`staking-rewards`](https://github.com/indexed-finance/staking-rewards) fork, except based more off SushiSwap's [original MasterChef](https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol) (v1).

Extends MasterChef to mint/burn an NFT ([ERC-1155](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol)) upon deposit/withdraw so users can transfer their shares in each pool. Transfers of the NFT move all pending rewards associated with the staked LP amount to the recipient.

Includes a treasury contract to stake the NFT to earn additional rewards separate from the initial liquidity mining phase (e.g. earning a share of Overlay market trading fees).
