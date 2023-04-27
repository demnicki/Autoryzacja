BEGIN
  ords.enable_schema(
    p_enabled             => TRUE,
    p_schema              => 'WKSP_KURS',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'api',
    p_auto_rest_auth      => FALSE
  );    
  COMMIT;
END;

BEGIN
  ords.define_module(
    p_module_name    => 'autoryzacja',
    p_base_path      => 'autoryzacja/',
    p_items_per_page => 0);
  COMMIT;
END;

BEGIN
  ords.define_module(
    p_module_name    => 'menu',
    p_base_path      => 'menu/',
    p_items_per_page => 0);
  COMMIT;
END;