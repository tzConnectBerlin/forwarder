 {
  admin = {
    admin = ("KT1JgF4RmwYQ42K4rPjkGw4qz7hrjmBjBmCS" : address);
    pending_admin = (None : address option);
    paused = true;
  };
  assets = {
    ledger = (Big_map.empty : ledger);
    operators = (Big_map.empty : operator_storage);
    token_total_supply = (Big_map.empty : token_total_supply);
    token_metadata = (Big_map.empty : token_metadata_storage);
  };
  metadata = Big_map.literal [
    ("", 0x697066733a2f2f516d6273396e4a4471447339586642746f7031686d4c43367879664d6364426d375836566b62646d50356f4135730a)
  ];
}

