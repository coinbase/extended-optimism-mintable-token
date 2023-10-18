import { ExtendedOptimismMintableTokenInstance } from "../@types/generated/contracts/ExtendedOptimismMintableToken";
import { TestParams } from "./helpers";
import { testTransferWithAuthorization } from "./testTransferWithAuthorization";
import { testCancelAuthorization } from "./testCancelAuthorization";
import { testReceiveWithAuthorization } from "./testReceiveWithAuthorization";
import { testPermit } from "./testPermit";

export function hasGasAbstraction(
  getFiatToken: () => ExtendedOptimismMintableTokenInstance,
  getDomainSeparator: () => string,
  fiatTokenOwner: string,
  rolesAdminBlacklisterPauser: string,
  accounts: Truffle.Accounts
): void {
  describe("GasAbstraction", () => {
    const testParams: TestParams = {
      getFiatToken,
      getDomainSeparator,
      fiatTokenOwner,
      rolesAdminBlacklisterPauser,
      accounts,
    };

    describe("EIP-3009", () => {
      testTransferWithAuthorization(testParams);
      testReceiveWithAuthorization(testParams);
      testCancelAuthorization(testParams);
    });

    describe("EIP-2612", () => {
        testPermit(testParams);
    })

  });
}
