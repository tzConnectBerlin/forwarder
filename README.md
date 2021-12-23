# Forwarding contract


Contract to forward transfers and mints to another, when authorized.

This contract ('forwarder') exists in order that owners of NFTs may
   know that they we minted with the approval of a specific account.

The contract is originated with an account set as 'owner'. The owner
   may authorize a contract as mint destination ('contract') and an
   address which is allowed to call this contract ('approved'). It is
   expected that the forwarder will be the admin of that (FA2)
   contract.

All create_token, mint and transfer calls will be sent to the approved
   contract iff they are from the approved account.

When the owner wishes to remove their approval, they call
   'disapprove', which causes this contract to become inactive and
   refuse all further calls.

(c) 2021 TZ Connect GmbH

Author: @johnsnewby

## Installation

run `deploy.sh`

If you're not running Linux this is very unlikely to work.

### PyTezos invocation

```
>>> from pytezos import pytezos
>>> shell = pytezos.using(shell='http://vastly.tzconnect.berlin:10734', key='edsk46Mr4xzyBxsBJXs3scYzAfx3RGRcZfwDsBxkHqTonqAnKksiVa')
>>> contract = shell.contract('KT1CJX8YGELVt39mrwKm2tw1Az1RCbf9FfJ7')
>>> contract.approve("tz1Memd9efwKKmmomKwuEM1aCQ5yvadS9hH9", "KT1GdKPHE6aYFra1fFio9gYezK9xhAnXMuGW").inject()
>>> contract.create_token({"token_id": 1, "token_info": { } }).inject()
>>> contract.mint_Tokens([{"owner": "tz1dU42fjGdiD7XHLnU8iEMEwe9AKiBwQVZs", "token_id": 1, "amount": 1}]).inject()
```
