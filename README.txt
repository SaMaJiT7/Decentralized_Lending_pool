REMIX DEFAULT WORKSPACE

Remix default workspace is present when:
i. Remix loads for the very first time 
ii. A new workspace is created with 'Default' template
iii. There are no files existing in the File Explorer

This workspace contains 3 directories:

1. 'contracts': Holds three contracts with increasing levels of complexity.
2. 'scripts': Contains four typescript files to deploy a contract. It is explained below.
3. 'tests': Contains one Solidity test file for 'Ballot' contract & one JS test file for 'Storage' contract.

SCRIPTS

The 'scripts' folder has two typescript files which help to deploy the 'Storage' contract using 'ethers.js' libraries.

For the deployment of any other contract, just update the contract name from 'Storage' to the desired contract and provide constructor arguments accordingly 
in the file `deploy_with_ethers.ts`

In the 'tests' folder there is a script containing Mocha-Chai unit tests for 'Storage' contract.

To run a script, right click on file name in the file explorer and click 'Run'. Remember, Solidity file must already be compiled.
Output from script will appear in remix terminal.

Please note, require/import is supported in a limited manner for Remix supported modules.
For now, modules supported by Remix are ethers, swarmgw, chai, multihashes, remix and hardhat only for hardhat.ethers object/plugin.
For unsupported modules, an error like this will be thrown: '<module_name> module require is not supported by Remix IDE' will be shown.


# Decentralized Lending Pool (Project 8)

A robust DeFi lending platform built on Ethereum that allows lenders to earn interest and borrowers to access collateral-free liquidity with automated interest calculations.

## 🚀 Key Technical Features
- **Time-Based Interest:** Uses `block.timestamp` to calculate interest precisely in Wei.
- **Refund Pattern:** Implemented `>=` repayment logic with an automatic refund mechanism to solve the "moving target" interest problem.
- **Proportional Profit Sharing:** Interest is distributed to lenders based on their share of the total pool principal.
- **Risk Management:** Public `checkDefault` function to flag overdue loans.

---

## 🛠 Step-by-Step Testing Guide (Remix IDE)

Follow these steps in order to verify the full lifecycle of the contract.

### 1. Pool Initialization (Lenders)
1. **Lender A:** Select **Account 1**, set Value to **10 Ether**, and click `deposit`.
2. **Lender B:** Select **Account 2**, set Value to **10 Ether**, and click `deposit`.
3. **Verify:** Call `getPoolBalance`. It should return `20000000000000000000` (20 ETH).

### 2. Borrowing Logic
1. **Borrower:** Select **Account 3**.
2. **Action:** Call `borrow` with:
   - `amount`: `5000000000000000000` (5 ETH)
   - `durationDays`: `30`
3. **Verify:** Account 3's wallet balance increases. `hasActiveLoan` is now `true`.

### 3. Repayment & Proportional Interest
1. **Wait:** Wait a few moments for interest to accrue (or use Remix "fast-forward").
2. **Repay:** From **Account 3**, set Value to **6 Ether** (overpayment) and click `repay`.
3. **Verify:** - The contract keeps the `Principal + Interest`.
   - The extra `~0.99 ETH` is automatically **refunded** to Account 3.
   - `totalLenderPrincipal` increases by the interest amount.

### 4. Profit Withdrawal
1. **Withdraw:** Switch to **Account 1** (Lender A).
2. **Action:** Call `withdraw` with original principal: `10000000000000000000` (10 ETH).
3. **Verify:** The lender receives their **10 ETH + 50% of the total interest** paid. Check the `Withdrawn` event log for the final amount (> 10 ETH).

### 5. Default Monitoring
1. **Action:** Call `checkDefault` with a borrower's address.
2. **Logic:** - If before `dueAt`: Transaction succeeds but no log is emitted.
   - If after `dueAt`: `DefaultDetected` event is emitted with total debt and time overdue.
   - If loan is already paid: Transaction **reverts** with "No active loan."

---

## 📊 Technical Formulas Used

- **Annual Interest Rate:** 10%
- **Interest Calculation:** $$Interest = \frac{Principal \times Rate \times SecondsElapsed}{365\ days \times 100}$$
- **Proportional Share:** $$Payout = \frac{Amount \times CurrentPoolBalance}{TotalLenderPrincipal}$$

---

**Developed as part of the Blockchain Development Module.**