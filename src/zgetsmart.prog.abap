*&---------------------------------------------------------------------*
*& Report ZGETSMART
*&---------------------------------------------------------------------*
*& Description: GetSmart is a simple tool to export Smartform texts
*&              to SO10 textnodes; it may or may not evolve into
*&              something a little user-friendlier.
*& Author:      Andrea Borgia
*&---------------------------------------------------------------------*
REPORT zgetsmart.

TABLES: stxftxt.


SELECTION-SCREEN BEGIN OF BLOCK bl1.
  PARAMETERS: p_sform  LIKE stxftxt-formname OBLIGATORY,
              p_iname  TYPE stxftxt-iname OBLIGATORY,
              p_tdname TYPE tdobname OBLIGATORY.
  SELECT-OPTIONS: s_spras FOR stxftxt-spras.
SELECTION-SCREEN END OF BLOCK bl1.


CONSTANTS: c_formtext     TYPE tdtxtype VALUE 'F',
           c_textobject   TYPE tdobject VALUE 'TEXT',
           c_standardtext TYPE tdid VALUE 'ST'.


DATA: gt_stxftxt TYPE STANDARD TABLE OF stxftxt,
      g_header   TYPE thead,
      gt_lines   TYPE tsftext,
      wa_line    TYPE tline.


START-OF-SELECTION.
  SELECT *
    FROM stxftxt
    INTO CORRESPONDING FIELDS OF TABLE gt_stxftxt
    WHERE spras IN s_spras
      AND txtype = c_formtext
      AND formname = p_sform
      AND iname = p_iname
    ORDER BY iname ASCENDING spras ASCENDING linenr ASCENDING.

* FIXME: until I figure out downport (issue #3), this is out:
*  gt_lines = CORRESPONDING #( gt_stxftxt ).
  LOOP AT gt_stxftxt ASSIGNING FIELD-SYMBOL(<fs_stxftxt>).
    AT NEW iname.
      CLEAR gt_lines[].
      CLEAR g_header.
      g_header-tdspras = <fs_stxftxt>-spras.
    ENDAT.

    MOVE-CORRESPONDING <fs_stxftxt> TO wa_line.
    APPEND wa_line TO gt_lines.

    AT END OF iname.
      g_header-tdobject = c_textobject.
      g_header-tdname = p_tdname.
      g_header-tdid = c_standardtext.

      CALL FUNCTION 'SAVE_TEXT'
        EXPORTING
*         CLIENT   = SY-MANDT
          header   = g_header
*         INSERT   = ' '
*         SAVEMODE_DIRECT         = ' '
*         OWNER_SPECIFIED         = ' '
*         LOCAL_CAT               = ' '
*         KEEP_LAST_CHANGED       = ' '
*  IMPORTING
*         FUNCTION =
*         NEWHEADER               =
        TABLES
          lines    = gt_lines
        EXCEPTIONS
          id       = 1
          language = 2
          name     = 3
          object   = 4
          OTHERS   = 5.
      IF sy-subrc = 0.
        WRITE: / 'Text saved, remember to add it to TR:', g_header-tdname, g_header-tdspras.
      ELSE.
        WRITE: / 'Error saving text:', g_header-tdname, g_header-tdspras.
      ENDIF.
    ENDAT.

  ENDLOOP.
