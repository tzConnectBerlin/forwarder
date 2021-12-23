LIGO=ligo

%.tz : %.mligo
	$(LIGO) compile contract $< -e main > $@

all:	forwarder.tz storage.tz

clean:
	rm *.tz

storage.tz: storage.mligo
	$(LIGO) compile storage forwarder.mligo '$(shell cat storage.mligo  | sed -e s/ADMIN_ACCOUNT/${ADMIN_ACCOUNT}/)'  -e main > $@

check:	check_approve_fail check_approve_success \
	check_disapprove_fail check_disapprove_success \
	check_disapprove_honoured

multi-asset.tz: smart-contracts/multi_asset/ligo/src/fa2_multi_asset.mligo
	$(LIGO) compile contract $< -e multi_asset_main > $@

multi-asset-storage.tz: smart-contracts/multi_asset/ligo/src/fa2_multi_asset.mligo multi-asset-storage.mligo
	$(LIGO) compile storage $< '$(shell cat multi-asset-storage.mligo)' -e multi_asset_main > $@

check_approve_fail:
	@echo 'should be failwith(1)'
	@$(LIGO) run interpret 'main (Approve ((("tz1WWcuiKUN4Ed5zouETqr7MbVzd3vkC4ubr" : address), ("KT1WQ1HWTQEZ1tSh2VmjxJ1xJCGz7kUQp35z" : address))), $(shell cat test-storage.mligo))' --init-file forwarder.mligo
	@echo

check_approve_success:
	@echo 'should be storage with'
	@echo '         record[approved -> SOME(@"tz1WWcuiKUN4Ed5zouETqr7MbVzd3vkC4ubr") ,'
	@echo '      	contract -> SOME(@"KT1WQ1HWTQEZ1tSh2VmjxJ1xJCGz7kUQp35z")'
	@$(LIGO) run interpret 'main (Approve  ((("tz1WWcuiKUN4Ed5zouETqr7MbVzd3vkC4ubr" : address), ("KT1WQ1HWTQEZ1tSh2VmjxJ1xJCGz7kUQp35z" : address))), $(shell cat test-storage.mligo))' --init-file forwarder.mligo --sender tz1WWcuiKUN4Ed5zouETqr7MbVzd3vkC4ubr
	@echo

check_disapprove_fail:
	@echo 'should be failwith(1)'
	@$(LIGO) run interpret 'main (Disapprove unit, $(shell cat test-storage.mligo))' --init-file forwarder.mligo
	@echo

check_disapprove_success:
	@echo 'should be contract with defunct -> True(unit) ,'
	@$(LIGO) run interpret 'main (Disapprove unit, $(shell cat test-storage.mligo))' --init-file forwarder.mligo --sender tz1WWcuiKUN4Ed5zouETqr7MbVzd3vkC4ubr
	@echo

check_disapprove_honoured:
	@echo "Should be failwith(0)"
	@$(LIGO) run interpret 'main (Approve  ((("tz1WWcuiKUN4Ed5zouETqr7MbVzd3vkC4ubr" : address), ("KT1WQ1HWTQEZ1tSh2VmjxJ1xJCGz7kUQp35z" : address))), $(shell cat test-storage-defunct.mligo))' --init-file forwarder.mligo --sender tz1WWcuiKUN4Ed5zouETqr7MbVzd3vkC4ubr
