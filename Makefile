include .env


.PHONY: install-foundry
install-foundry:
	curl -L https://foundry.paradigm.xyz | bash
	~/.foundry/bin/foundryup --commit $(FOUNDRY_COMMIT)


.PHONY: build
build: solidity-deps
	   yarn install

.PHONY: solidity-deps
solidity-deps: checkout-op-commit
	forge install --no-commit --no-git github.com/foundry-rs/forge-std \
		github.com/OpenZeppelin/openzeppelin-contracts@v4.7.3 \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.7.3 \
		github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc \

.PHONY: checkout-op-commit
checkout-op-commit:
	[ -n "$(OP_COMMIT)" ] || (echo "OP_COMMIT must be set in .env" && exit 1)
	rm -rf lib/optimism
	mkdir -p lib/optimism
	cd lib/optimism; \
	git init; \
	git remote add origin https://github.com/ethereum-optimism/optimism.git; \
	git fetch --depth=1 origin $(OP_COMMIT); \
	git reset --hard FETCH_HEAD

.PHONY: tests
tests:
	npx hardhat test && forge test

.PHONY: coverage
coverage:
	forge coverage && npx hardhat clean && npx hardhat coverage

.PHONY: deploy
deploy:
	@forge script --sender $(DEPLOYER) -- broadcast --rpc-url $(RPC_URL) --sig "run()" DeployExtendedOptimismMintableToken

.PHONY: deploy-local
deploy-local:
	forge script --sender $(DEPLOYER) --sig "run()" DeployExtendedOptimismMintableToken
