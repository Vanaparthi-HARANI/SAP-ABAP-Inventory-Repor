REPORT zinventory_report.

TABLES: mara, mard.

*--- Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: so_plant FOR mard-werks OBLIGATORY,
                  so_mtart FOR mara-mtart.
  PARAMETERS:     p_minqty TYPE mard-labst DEFAULT 10.
SELECTION-SCREEN END OF BLOCK b1.

*--- Type Definitions
TYPES: BEGIN OF ty_inventory,
         matnr TYPE mara-matnr,
         mtart TYPE mara-mtart,
         werks TYPE mard-werks,
         labst TYPE mard-labst,
         meins TYPE mara-meins,
         maktx TYPE makt-maktx,
         light TYPE c LENGTH 1,    "# fixed
       END OF ty_inventory.

*--- Internal Table & Work Area
DATA: it_inventory TYPE TABLE OF ty_inventory,
      wa_inventory TYPE ty_inventory.

*--- Start of Selection
START-OF-SELECTION.

  SELECT a~matnr
         a~mtart
         a~meins
         d~werks
         d~labst
         t~maktx
    INTO CORRESPONDING FIELDS OF TABLE it_inventory
    FROM mara AS a
    INNER JOIN mard AS d ON d~matnr = a~matnr
    INNER JOIN makt AS t ON t~matnr = a~matnr
   WHERE d~werks IN so_plant
     AND a~mtart IN so_mtart
     AND t~spras = sy-langu.

*--- Filter materials below minimum stock quantity
  DELETE it_inventory WHERE labst >= p_minqty.

*--- Assign traffic light values
*--- Assign traffic light values (demo)
  DATA: lv_counter TYPE i VALUE 0.

  LOOP AT it_inventory INTO wa_inventory.
    lv_counter = lv_counter + 1.

    IF lv_counter MOD 3 = 1.
      wa_inventory-light = '1'.
      wa_inventory-labst = 0.
    ELSEIF lv_counter MOD 3 = 2.
      wa_inventory-light = '2'.
      wa_inventory-labst = 5.
    ELSE.
      wa_inventory-light = '3'.
      wa_inventory-labst = 50.
    ENDIF.

    MODIFY it_inventory FROM wa_inventory.
  ENDLOOP.
*--- Check if any records found
  IF it_inventory IS INITIAL.
    MESSAGE 'No materials found below the entered stock quantity' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

*--- ALV Display
  DATA: lt_fcat   TYPE slis_t_fieldcat_alv,
        wa_fcat   TYPE slis_fieldcat_alv,
        lt_layout TYPE slis_layout_alv.

*--- Layout settings
  lt_layout-zebra             = 'X'.
  lt_layout-colwidth_optimize = 'X'.
  lt_layout-lights_fieldname  = 'LIGHT'.

*--- Build Field Catalog
  DEFINE m_fcat.
    CLEAR wa_fcat.
    wa_fcat-fieldname = &1.
    wa_fcat-seltext_m = &2.
    wa_fcat-col_pos   = &3.
    APPEND wa_fcat TO lt_fcat.
  END-OF-DEFINITION.

  m_fcat 'MATNR' 'Material No'   1.
  m_fcat 'MAKTX' 'Description'   2.
  m_fcat 'WERKS' 'Plant'         3.
  m_fcat 'MTART' 'Material Type' 4.
  m_fcat 'LABST' 'Stock Qty'     5.
  m_fcat 'MEINS' 'Unit'          6.
  m_fcat 'LIGHT' 'Status'        7.

*--- Call ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      it_fieldcat = lt_fcat        "# removed i_structure_name
      is_layout   = lt_layout
    TABLES
      t_outtab    = it_inventory
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.
