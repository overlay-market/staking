# backlog

Things that need to be done, checked, verified, tested, etc.


- [x] Set "uri" => Rainbow Destruction Cats uri

- [x] mint/burn ERC1155 in deposit/withdraw

- [ ] SUSHI => OVL

- [x] alter init of original master chef tests to give minter role to chef contract for reward token

- [x] transfer() function overrides to change userInfo

- [x] Fix transfer() rewardDebt update logic in _beforeTokenTransfer hook

- [ ] Test transfer function hook HEAVILY to make sure is ok
  - [ ] Verify reward debt and amounts remain in sync
  - [ ] Verify harvested rewards prior to transfer are done properly
  - [ ] Check edge cases e.g., send multiple of the same id in hook


- [ ] Test harvest function

- [x] Zero out staking credit balance on emergency withdraw

- [ ] Test emergency withdraw HEAVILY to make sure is ok

- [ ] Treasury.sol (ERC1155 compatible/receiver)

- [x] Investigate adding Keep3rV2OracleFactory.update(pair) call on updatePool()
  - [x] MasterChefToken needs to register as keeper?: Y OR remove keeper modifier on kv2of.update()
  - [x] Keep3rV2OracleFactory.update(pair)/Keep3rV2Oracle.update() doesn't revert?: only on factory, keeper modifiers
  - [x] keeper modifier on kv2of.update(): would revert if not keeper calling => need to register MasterChefToken as keeper or remove
  - [x] factory modifier on kv2o.update(): would revert if not factory calling => need to call kv2of.update(pair)
  - [x] kv2of.update(pair) && kv2o.update(pair) returns bool
  - IUniwapV2Pair(pair) methods revert?:
    - [x] getReserves() reverts?: N
    - [x] priceCumulativeLast() reverts?: N
