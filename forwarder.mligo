(*

Contract to forward transfers and mints to another, when authorized.

This contract ('forwarder') exists in order that owners of NFTs may
   know that they were minted with the approval of a specific account.

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

The `transfer` call will only be implemented if `TRANSFER_ENABLE` is
   `#define`d

(c) 2021 TZ Connect GmbH

Author: @johnsnewby

 *)



(*
below lifted from https://github.com/oxheadalpha/smart-contracts
*)
type token_id = nat

type mint_burn_tx =
[@layout:comb]
{
  owner : address;
  token_id : token_id;
  amount : nat;
}

type mint_burn_tokens_param = mint_burn_tx list

type transfer_destination =
[@layout:comb]
{
  to_ : address;
  token_id : token_id;
  amount : nat;
}

type transfer =
[@layout:comb]
{
  from_ : address;
  txs : transfer_destination list;
}

type transfer_param = transfer list

type token_metadata =
[@layout:comb]
{
  token_id : token_id;
  token_info : (string, bytes) map;
}

type storage = {
    contract: address option;
    approved: address option;
    owner: address;
    defunct: bool;
  }

type parameter =
   | Approve of (address * address)
   | Disapprove of unit
   | Create_token of token_metadata
   | Mint_tokens of mint_burn_tokens_param
#if TRANSFER_ENABLED
   | Transfer of transfer_param
#endif

type return = (operation list * storage)

(**************************************************************)
let defunct : nat =      0n
let auth : nat =         1n
let noapp : nat =        2n
let not_approved : nat = 3n
let already_set : nat =  4n
let no_contract : nat =  5n
let not_found : nat =    6n

[@inline]
let check_defunct (store : storage) : unit =
  let _ = if store.defunct then (failwith defunct) in
  unit

[@inline]
let check_owner (store : storage) : unit =
  let _ = if store.owner <> Tezos.sender then (failwith auth) in
  unit

[@inline]
let check_approved (store : storage) : unit =
  match store.approved with
  | None -> failwith noapp
  | Some x -> if x = Tezos.sender then unit else failwith not_approved


(*
set the account which may mint and the contract
- if the contract is turned off (defunct) fail.
- if the caller is not the owner of the contract, fail.
- if the user is already set, fail.
- otherwise, approve the account
 *)
let approve (store, approve_addr, contract_addr : storage * address * address) :
      return =
  let _ = check_defunct store in
  let _ = check_owner store in
  match store.approved with
  | Some _ -> (failwith already_set : return)
  | None -> (([]: operation list), {
               store with approved = Some approve_addr;
                          contract = Some contract_addr;
            })

(*
shut down this contract
- if the contract is already turned off (defunct) fail.
- if the caller is not the owner of the contract, fail.
- otherwise set the defunct flag
 *)
let disapprove (store : storage) : return =
  let _ = check_defunct store in
  let _ = check_owner store in
  (([]: operation list), { store with defunct = true })

(*
accept a create token call, and send it to the target contract.
- if the contract is defunct, fail.
- if the caller is not the approved user, fail.
- if there is no contract set, fail.
- otherwise, send the call to the target contract.
 *)
let create_token (store, param : storage * token_metadata) =
  let _ = check_defunct store in
  let _ = check_approved store in
  let c = match store.contract with
  | None -> (failwith no_contract : address)
  | Some c -> c in
  match (Tezos.get_entrypoint_opt "%create_token" c :
           token_metadata contract option) with
              | None -> (failwith not_found : return)
              | Some e -> ([(Tezos.transaction param 0tez e)], store)

(*
accept a mint call, and send it to the target contract.
- if the contract is defunct, fail.
- if the caller is not the approved user, fail.
- if there is no contract set, fail.
- otherwise, send the call to the target contract.
 *)
let mint_tokens (store, param : storage * mint_burn_tokens_param) =
  let _ = check_defunct store in
  let _ = check_approved store in
  let c = match store.contract with
  | None -> (failwith no_contract : address)
  | Some c -> c in
  match (Tezos.get_entrypoint_opt "%mint_tokens" c :
           mint_burn_tokens_param contract option) with
              | None -> (failwith not_found : return)
              | Some e -> ([(Tezos.transaction param 0tez e)], store)

(*
accept a transfer call, and send it to the target contract.
- if the contract is defunct, fail.
- if the caller is not the approved user, fail.
- if there is no contract set, fail.
- otherwise, send the call to the target contract.
 *)
let transfer (store, param : storage * transfer_param) =
  let _ = check_defunct store in
  let _ = check_approved store in
  let c = match store.contract with
  | None -> (failwith no_contract : address)
  | Some c -> c in
  match (Tezos.get_entrypoint_opt "%transfer" c :
           transfer_param contract option) with
              | None -> (failwith not_found : return)
              | Some e -> ([(Tezos.transaction param 0tez e)], store)

let main (action, store : parameter * storage) : operation list * storage =
  match action with
  | Approve (approve_addr, contract_addr) ->
     approve (store, approve_addr, contract_addr)
  | Disapprove _ -> disapprove (store)
  | Create_token param -> create_token (store, param)
  | Mint_tokens param -> mint_tokens (store, param)
#if TRANSFER_ENABLED
  | Transfer param -> transfer (store, param)
#endif
