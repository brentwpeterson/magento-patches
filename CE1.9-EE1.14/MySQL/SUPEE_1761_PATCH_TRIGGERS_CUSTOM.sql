DELIMITER ;;
/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_after_insert
AFTER INSERT
ON mgn_catalog_category_entity FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_cat_cl` (`category_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_after_update
AFTER UPDATE
ON mgn_catalog_category_entity FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_cat_cl` (`category_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_after_delete
AFTER DELETE
ON mgn_catalog_category_entity FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_cat_cl` (`category_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_datetime_after_insert
AFTER INSERT
ON mgn_catalog_category_entity_datetime FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_datetime_after_update
AFTER UPDATE
ON mgn_catalog_category_entity_datetime FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_datetime_after_delete
AFTER DELETE
ON mgn_catalog_category_entity_datetime FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_decimal_after_insert
AFTER INSERT
ON mgn_catalog_category_entity_decimal FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_decimal_after_update
AFTER UPDATE
ON mgn_catalog_category_entity_decimal FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_decimal_after_delete
AFTER DELETE
ON mgn_catalog_category_entity_decimal FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_int_after_insert
AFTER INSERT
ON mgn_catalog_category_entity_int FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_cat_cl` (`category_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_int_after_update
AFTER UPDATE
ON mgn_catalog_category_entity_int FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_cat_cl` (`category_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_int_after_delete
AFTER DELETE
ON mgn_catalog_category_entity_int FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_cat_cl` (`category_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_text_after_insert
AFTER INSERT
ON mgn_catalog_category_entity_text FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_text_after_update
AFTER UPDATE
ON mgn_catalog_category_entity_text FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_text_after_delete
AFTER DELETE
ON mgn_catalog_category_entity_text FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_url_key_after_insert
AFTER INSERT
ON mgn_catalog_category_entity_url_key FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_category_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_url_key_after_update
AFTER UPDATE
ON mgn_catalog_category_entity_url_key FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_category_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_url_key_after_delete
AFTER DELETE
ON mgn_catalog_category_entity_url_key FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_category_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_varchar_after_insert
AFTER INSERT
ON mgn_catalog_category_entity_varchar FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_varchar_after_update
AFTER UPDATE
ON mgn_catalog_category_entity_varchar FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_entity_varchar_after_delete
AFTER DELETE
ON mgn_catalog_category_entity_varchar FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_product_after_insert
AFTER INSERT
ON mgn_catalog_category_product FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_index_cl` (`product_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_product_after_update
AFTER UPDATE
ON mgn_catalog_category_product FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_index_cl` (`product_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_category_product_after_delete
AFTER DELETE
ON mgn_catalog_category_product FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_category_product_index_cl` (`product_id`) VALUES (OLD.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_eav_attribute_after_insert
AFTER INSERT
ON mgn_catalog_eav_attribute FOR EACH ROW
BEGIN
CASE (NEW.is_searchable = 1) OR (NEW.is_visible_in_advanced_search = 1) OR (NEW.is_filterable > 0) OR (NEW.is_filterable_in_search = 1) OR (NEW.used_for_sort_by = 1) OR (NEW.is_used_for_promo_rules = 1) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '5'); END; ELSE BEGIN END; END CASE;
END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_eav_attribute_after_update
AFTER UPDATE
ON mgn_catalog_eav_attribute FOR EACH ROW
BEGIN
CASE (NEW.is_searchable IS NOT NULL AND NEW.is_searchable != OLD.is_searchable) OR (NEW.is_visible_in_advanced_search IS NOT NULL
                        AND
                        NEW.is_visible_in_advanced_search != OLD.is_visible_in_advanced_search) OR (NEW.is_filterable IS NOT NULL AND NEW.is_filterable != OLD.is_filterable) OR (NEW.is_filterable_in_search IS NOT NULL
                        AND
                        NEW.is_filterable_in_search != OLD.is_filterable_in_search) OR (NEW.used_for_sort_by IS NOT NULL AND NEW.used_for_sort_by != OLD.used_for_sort_by) OR (NEW.is_used_for_promo_rules IS NOT NULL
                            AND NEW.is_used_for_promo_rules != OLD.is_used_for_promo_rules) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '12'); END; ELSE BEGIN END; END CASE;
END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_eav_attribute_after_delete
AFTER DELETE
ON mgn_catalog_eav_attribute FOR EACH ROW
BEGIN
CASE (OLD.is_searchable = 1) OR (OLD.is_visible_in_advanced_search = 1) OR (OLD.is_filterable > 0) OR (OLD.is_filterable_in_search = 1) OR (OLD.used_for_sort_by = 1) OR (OLD.is_used_for_promo_rules = 1) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '10'); END; ELSE BEGIN END; END CASE;
END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_bundle_selection_after_insert
AFTER INSERT
ON mgn_catalog_product_bundle_selection FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`parent_product_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`parent_product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_bundle_selection_after_update
AFTER UPDATE
ON mgn_catalog_product_bundle_selection FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`parent_product_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`parent_product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_bundle_selection_after_delete
AFTER DELETE
ON mgn_catalog_product_bundle_selection FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (OLD.`parent_product_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`parent_product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_after_insert
AFTER INSERT
ON mgn_catalog_product_entity FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_after_update
AFTER UPDATE
ON mgn_catalog_product_entity FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_after_delete
AFTER DELETE
ON mgn_catalog_product_entity FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_datetime_after_insert
AFTER INSERT
ON mgn_catalog_product_entity_datetime FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_datetime_after_update
AFTER UPDATE
ON mgn_catalog_product_entity_datetime FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_datetime_after_delete
AFTER DELETE
ON mgn_catalog_product_entity_datetime FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_decimal_after_insert
AFTER INSERT
ON mgn_catalog_product_entity_decimal FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_decimal_after_update
AFTER UPDATE
ON mgn_catalog_product_entity_decimal FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_decimal_after_delete
AFTER DELETE
ON mgn_catalog_product_entity_decimal FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_int_after_insert
AFTER INSERT
ON mgn_catalog_product_entity_int FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_product_index_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_int_after_update
AFTER UPDATE
ON mgn_catalog_product_entity_int FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_product_index_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_int_after_delete
AFTER DELETE
ON mgn_catalog_product_entity_int FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_category_product_index_cl` (`product_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_text_after_insert
AFTER INSERT
ON mgn_catalog_product_entity_text FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_text_after_update
AFTER UPDATE
ON mgn_catalog_product_entity_text FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_text_after_delete
AFTER DELETE
ON mgn_catalog_product_entity_text FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_url_key_after_insert
AFTER INSERT
ON mgn_catalog_product_entity_url_key FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_product_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_url_key_after_update
AFTER UPDATE
ON mgn_catalog_product_entity_url_key FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_product_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_url_key_after_delete
AFTER DELETE
ON mgn_catalog_product_entity_url_key FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_product_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_varchar_after_insert
AFTER INSERT
ON mgn_catalog_product_entity_varchar FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_varchar_after_update
AFTER UPDATE
ON mgn_catalog_product_entity_varchar FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (NEW.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_entity_varchar_after_delete
AFTER DELETE
ON mgn_catalog_product_entity_varchar FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`entity_id`);
INSERT IGNORE INTO `mgn_catalog_product_flat_cl` (`entity_id`) VALUES (OLD.`entity_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_link_after_insert
AFTER INSERT
ON mgn_catalog_product_link FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`product_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_link_after_update
AFTER UPDATE
ON mgn_catalog_product_link FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`product_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_link_after_delete
AFTER DELETE
ON mgn_catalog_product_link FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (OLD.`product_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_super_link_after_insert
AFTER INSERT
ON mgn_catalog_product_super_link FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`parent_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`parent_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_super_link_after_update
AFTER UPDATE
ON mgn_catalog_product_super_link FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`parent_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (NEW.`parent_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_super_link_after_delete
AFTER DELETE
ON mgn_catalog_product_super_link FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (OLD.`parent_id`);
INSERT IGNORE INTO `mgn_catalogsearch_fulltext_cl` (`product_id`) VALUES (OLD.`parent_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_website_after_insert
AFTER INSERT
ON mgn_catalog_product_website FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`product_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_website_after_update
AFTER UPDATE
ON mgn_catalog_product_website FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`product_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalog_product_website_after_delete
AFTER DELETE
ON mgn_catalog_product_website FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (OLD.`product_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (OLD.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_cataloginventory_stock_item_after_insert
AFTER INSERT
ON mgn_cataloginventory_stock_item FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`product_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_cataloginventory_stock_item_after_update
AFTER UPDATE
ON mgn_cataloginventory_stock_item FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (NEW.`product_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_cataloginventory_stock_item_after_delete
AFTER DELETE
ON mgn_cataloginventory_stock_item FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_cataloginventory_stock_status_cl` (`product_id`) VALUES (OLD.`product_id`);
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (OLD.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalogrule_product_price_after_insert
AFTER INSERT
ON mgn_catalogrule_product_price FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`product_id`);

END */;;


/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalogrule_product_price_after_update
AFTER UPDATE
ON mgn_catalogrule_product_price FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (NEW.`product_id`);

END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_catalogrule_product_price_after_delete
AFTER DELETE
ON mgn_catalogrule_product_price FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_catalog_product_index_price_cl` (`entity_id`) VALUES (OLD.`product_id`);

END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_config_data_after_insert
AFTER INSERT
ON mgn_core_config_data FOR EACH ROW
BEGIN
CASE (NEW.path = 'catalog/price/scope') WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '13'); END; ELSE BEGIN END; END CASE;
CASE (NEW.path = 'cataloginventory/options/show_out_of_stock') OR (NEW.path = 'cataloginventory/item_options/manage_stock') WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '14'); END; ELSE BEGIN END; END CASE;
CASE (NEW.path = 'catalog/frontend/flat_catalog_product') AND (NEW.value = 1) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '15'); END; ELSE BEGIN END; END CASE;
CASE (NEW.path = 'catalog/frontend/flat_catalog_category') AND (NEW.value = 1) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '16'); END; ELSE BEGIN END; END CASE;
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_config_data_after_update
AFTER UPDATE
ON mgn_core_config_data FOR EACH ROW
BEGIN
CASE ((NEW.path = 'catalog/price/scope') AND (NEW.value != OLD.value)) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '13'); END; ELSE BEGIN END; END CASE;
CASE ((NEW.path = 'cataloginventory/options/show_out_of_stock') AND (NEW.value != OLD.value)) OR ((NEW.path = 'cataloginventory/item_options/manage_stock') AND (NEW.value != OLD.value)) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '14'); END; ELSE BEGIN END; END CASE;
CASE (NEW.path = 'catalog/frontend/flat_catalog_product') AND (NEW.value != OLD.value) AND (NEW.value = 1) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '15'); END; ELSE BEGIN END; END CASE;
CASE (NEW.path = 'catalog/frontend/flat_catalog_category') AND (NEW.value != OLD.value) AND (NEW.value = 1) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '16'); END; ELSE BEGIN END; END CASE;
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_config_data_after_delete
AFTER DELETE
ON mgn_core_config_data FOR EACH ROW
BEGIN
CASE (OLD.path = 'catalog/price/scope') WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '13'); END; ELSE BEGIN END; END CASE;
CASE (OLD.path = 'cataloginventory/options/show_out_of_stock') OR (OLD.path = 'cataloginventory/item_options/manage_stock') WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '14'); END; ELSE BEGIN END; END CASE;
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_store_after_insert
AFTER INSERT
ON mgn_core_store FOR EACH ROW
BEGIN
UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '2');
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_store_after_delete
AFTER DELETE
ON mgn_core_store FOR EACH ROW
BEGIN
UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '8');
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_store_group_after_insert
AFTER INSERT
ON mgn_core_store_group FOR EACH ROW
BEGIN
UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '3');
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_store_group_after_update
AFTER UPDATE
ON mgn_core_store_group FOR EACH ROW
BEGIN
CASE (OLD.root_category_id != NEW.root_category_id) WHEN TRUE THEN BEGIN UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '4'); END; ELSE BEGIN END; END CASE;
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_store_group_after_delete
AFTER DELETE
ON mgn_core_store_group FOR EACH ROW
BEGIN
UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '9');
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_core_website_after_delete
AFTER DELETE
ON mgn_core_website FOR EACH ROW
BEGIN
UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '7');
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_customer_group_after_insert
AFTER INSERT
ON mgn_customer_group FOR EACH ROW
BEGIN
UPDATE `enterprise_mview_metadata` AS `mm`
 INNER JOIN `enterprise_mview_metadata_event` AS `me` ON mgn_mm.metadata_id = me.metadata_id
SET `mm`.`status` = 2
WHERE (mview_event_id = '6');
END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_enterprise_url_rewrite_redirect_after_insert
AFTER INSERT
ON mgn_enterprise_url_rewrite_redirect FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_redirect_cl` (`redirect_id`) VALUES (NEW.`redirect_id`);

END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_enterprise_url_rewrite_redirect_after_update
AFTER UPDATE
ON mgn_enterprise_url_rewrite_redirect FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_redirect_cl` (`redirect_id`) VALUES (NEW.`redirect_id`);

END */;;



/*!50003 CREATE*/ /*!50003 TRIGGER trg_mgn_enterprise_url_rewrite_redirect_after_delete
AFTER DELETE
ON mgn_enterprise_url_rewrite_redirect FOR EACH ROW
BEGIN
INSERT IGNORE INTO `mgn_enterprise_url_rewrite_redirect_cl` (`redirect_id`) VALUES (OLD.`redirect_id`);

END */;;

