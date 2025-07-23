# PledgeChain Smart Contract

A Clarity smart contract for the Stacks blockchain that enables users to create and maintain accountability pledges backed by STX tokens.

## Overview

PledgeChain allows users to make commitments by staking STX tokens, requiring regular check-ins to maintain their pledge. If users fail to check in within specified intervals, their staked tokens are forfeited to a designated penalty address.

## Features

- Create customizable pledges with STX stakes
- Set flexible duration and check-in intervals
- Regular check-in mechanism to maintain active pledges
- Secure handling of STX tokens
- Transparent pledge status verification

## Contract Functions

### Public Functions

```clarity
(create-pledge (description string-utf8) (duration uint) (interval uint) (penalty-address principal) (amount uint))
```
Creates a new pledge with specified parameters and transfers STX from the user to the contract.

```clarity
(check-in (pledge-id uint))
```
Allows pledge owner to check in within the specified interval to maintain their pledge.

### Read-Only Functions

```clarity
(get-pledge (pledge-id uint))
```
Returns the details of a specific pledge.

```clarity
(has-checked-in (pledge-id uint) (checkin-block uint))
```
Verifies if a check-in occurred for a specific pledge at a given block height.

## Error Codes

| Code | Description |
|------|-------------|
| `u100` | Zero STX amount specified |
| `u101` | Not the pledge owner |
| `u102` | Pledge not active |
| `u103` | Invalid check-in window |
| `u104` | Already checked in |
| `u105` | Pledge not found |
| `u106` | Invalid duration |
| `u107` | Invalid interval |

## Usage Example

```clarity
;; Create a new pledge
(contract-call? .pledgechain create-pledge 
    "Daily exercise commitment" ;; description
    u43200                     ;; duration (30 days in blocks)
    u1440                      ;; interval (1 day in blocks)
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; penalty address
    u1000000)                  ;; amount (1 STX)

;; Check in to maintain pledge
(contract-call? .pledgechain check-in u1)
```



### Testing

```bash
clarinet test
```

