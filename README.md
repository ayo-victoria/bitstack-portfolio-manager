# BitStack Portfolio Manager

**BitStack Portfolio Manager** is a decentralized, non-custodial multi-asset portfolio management protocol built on the **Stacks** blockchain (Bitcoin Layer 2). It allows users to create, manage, and rebalance diversified crypto portfolios in a secure and gas-efficient way.

---

## 🧩 Summary

BitStack provides a smart contract-based system that enables:

* Creation of custom crypto portfolios
* Automated portfolio rebalancing
* Flexible allocation percentages
* Efficient storage and computation through batch operations

---

## 🚀 Features

* **Decentralized Portfolio Creation**
  Users can create diversified portfolios with up to 10 different tokens per portfolio.

* **Automated Rebalancing**
  Portfolios automatically flag for rebalancing based on block height thresholds (e.g., every \~24 hours).

* **Customizable Allocations**
  Each token's allocation can be individually set and later adjusted, with allocations validated to ensure they total 100%.

* **Gas-Efficient Architecture**
  Batch initialization logic and optimized storage access reduce transaction costs.

* **Secure Ownership and Access Control**
  Portfolio operations are restricted to the portfolio owner.

---

## 📐 Architecture Overview

```text
+-----------------------------+
|    BitStack Protocol Core  |
+-----------------------------+
|                             |
|  +-----------------------+  |
|  |   Portfolio Registry  |<------------------+
|  +-----------------------+  |                |
|                             |                |
|  +-----------------------+  |                |
|  |   Asset Allocations   |<------+           |
|  +-----------------------+  |     |           |
|                             |     |           |
|  +-----------------------+  |     |           |
|  |  User Portfolio Map   |<--+    |           |
|  +-----------------------+        |           |
|                                   |           |
+-----------------------------------+           |
                                                |
     Smart Contract Functions:                  |
     --------------------------                 |
     - create-portfolio()  ----------------------+
     - rebalance-portfolio()
     - update-portfolio-allocation()
     - get-portfolio()
     - get-portfolio-asset()
     - get-user-portfolios()
```

---

## 🛠️ Smart Contract Overview

### 📄 Core Contracts (Clarity)

* **Portfolio Registry**: Stores metadata about each portfolio (`owner`, `created-at`, `total-value`, etc.).
* **PortfolioAssets Map**: Tracks each token's allocation and current value within a portfolio.
* **UserPortfolios Map**: Stores which portfolios are owned by which user (max 20).

### ✅ Key Read-Only Functions

* `get-portfolio(portfolio-id)`
* `get-portfolio-asset(portfolio-id, token-id)`
* `get-user-portfolios(user)`
* `calculate-rebalance-amounts(portfolio-id)`

### 🔐 Key Public Functions

* `create-portfolio(tokens, percentages)`
* `rebalance-portfolio(portfolio-id)`
* `update-portfolio-allocation(portfolio-id, token-id, new-percentage)`
* `initialize(new-owner)`

---

## 📊 Example Use Case

A user wants to create a portfolio with the following assets and allocations:

* STX: 40%
* USDC: 30%
* BTC-wrapped: 30%

The user calls `create-portfolio()` with:

```clojure
(initial-tokens (list STX-address USDC-address BTC-address))
(percentages (list u4000 u3000 u3000))
```

---

## ⚠️ Error Codes

| Code | Name                     | Description                             |
| ---- | ------------------------ | --------------------------------------- |
| 100  | ERR-NOT-AUTHORIZED       | Action attempted by unauthorized user   |
| 101  | ERR-INVALID-PORTFOLIO    | Portfolio not found or is invalid       |
| 102  | ERR-INSUFFICIENT-BALANCE | Insufficient funds for operation        |
| 103  | ERR-INVALID-TOKEN        | Invalid token provided                  |
| 104  | ERR-REBALANCE-FAILED     | Rebalance operation failed              |
| 105  | ERR-PORTFOLIO-EXISTS     | Attempt to duplicate existing portfolio |
| 106  | ERR-INVALID-PERCENTAGE   | Invalid allocation percentage input     |
| 107  | ERR-MAX-TOKENS-EXCEEDED  | Too many tokens in one portfolio        |
| 108  | ERR-LENGTH-MISMATCH      | Tokens and percentages length mismatch  |
| 109  | ERR-USER-STORAGE-FAILED  | Could not update user’s portfolio list  |
| 110  | ERR-INVALID-TOKEN-ID     | Token index out of bounds or not found  |

---

## 🔐 Security Considerations

* All state-mutating functions verify ownership (`tx-sender`) to prevent unauthorized access.
* Internal helper functions validate all inputs rigorously.
* Allocation percentages are strictly checked to ensure they sum to 100% (in basis points).

---

## 📚 Requirements

* **Stacks blockchain**
* **Clarity smart contract language**
* Clarity tools (e.g., [Clarinet](https://github.com/hirosystems/clarinet)) for testing/deployment

---

## 👨‍💻 Contributing

Feel free to open issues or submit PRs if you want to extend the protocol or report bugs. All contributions should be well-documented and covered by tests.
