BEGIN
  ords.define_template(
    p_module_name    => 'menu',
    p_pattern        => 'gen_menu/');

  ords.define_handler(
    p_module_name    => 'menu',
    p_pattern        => 'gen_menu/',
    p_method         => 'POST',
    p_source_type    => ords.source_type_plsql,
    p_source         => q'[DECLARE
                        z_zapytanie JSON_OBJECT_T;
                        z_odpowiedz JSON_OBJECT_T;
                        BEGIN
                        z_zapytanie := JSON_OBJECT_T(:b_zapytanie);
                        menu_dynamiczne.gen_menu(
                        zapytanie => z_zapytanie,
                        odpowiedz => z_odpowiedz);
                        owa_util.mime_header('application/json', true, 'UTF-8');
                        htp.prn(z_odpowiedz.stringify);
                        END;]',
    p_items_per_page => 0);

  ords.define_parameter(
    p_module_name        => 'menu',
    p_pattern            => 'gen_menu/',
    p_method             => 'POST',
    p_name               => 'b_zapytanie',
    p_bind_variable_name => 'b_zapytanie',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'IN'
    );
  
  COMMIT;
END;