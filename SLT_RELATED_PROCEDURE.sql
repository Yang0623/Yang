USE [NAMDW]
GO

/****** Object:  StoredProcedure [DW].[SP_SYS_ETL_LOG]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [DW].[SP_SYS_ETL_LOG]
  --Record log into log table
  --Creadted by   : Daniel
  --Vserion       : 1.0
  --Modify History: Create
  @PROJECT_NAME	NVARCHAR (100),
  @PROCESS_NAME	NVARCHAR(100),
  @SUB_PROCESS_NAME	NVARCHAR(100),
  @MSG_LEVEL	NVARCHAR(50),
  @MSG_TEXT1	NVARCHAR (100),
  @MSG_TEXT2	NVARCHAR (100),
  @MSG_TEXT3	NVARCHAR (100)
AS

BEGIN

	BEGIN TRAN INSERT_LOG

	INSERT INTO DW.SYS_ETL_LOG 
			([PROJECT_NAME],
	    [PROCESS_NAME],
	    [SUB_PROCESS_NAME],
	    [PROCESS_DATE],
	    [MSG_LEVEL],
	    [MSG_TEXT1],
	    [MSG_TEXT2],
	    [MSG_TEXT3])
	VALUES
	    (@PROJECT_NAME,
	    @PROCESS_NAME,
	    @SUB_PROCESS_NAME,
	    GETDATE(),
	    @MSG_LEVEL,
	    @MSG_TEXT1,
	    @MSG_TEXT2,
	    @MSG_TEXT3);
        
     COMMIT TRAN INSERT_LOG   

 END


GO


/****** Object:  StoredProcedure [DW].[SP_SYS_ETL_STATUS]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [DW].[SP_SYS_ETL_STATUS]
  --Record log into log table
  --Creadted by   : Daniel
  --Vserion       : 1.0
  --Modify History: Create
  @PROJECT_NAME	NVARCHAR (100),
  @PROCESS_NAME	NVARCHAR(50),
  @LEVEL	NVARCHAR(10),
  @STATUS	NVARCHAR (20)
AS

BEGIN

	BEGIN TRAN INSERT_LOG

		INSERT INTO DW.SYS_ETL_STATUS
				(
				PROJECT_NAME,
				PROCESS_NAME,
				PROCESS_TIME,
				LEVEL,
				STATUS
				)
		VALUES 
				(
				@PROJECT_NAME,
				@PROCESS_NAME,
				GETDATE(),	--SYSTIME
				@LEVEL,
				@STATUS
				);
        
  COMMIT TRAN INSERT_LOG   

 END


GO

/****** Object:  StoredProcedure [DW].[SP_D_ARTICLE_DESC_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [DW].[SP_D_ARTICLE_DESC_SAP]
  --Load data from staging to warehouse
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create
AS

    DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @PROJECT_NAME varchar(50)
    DECLARE @FILE_ID INT
    DECLARE @FILE_NAME varchar(50)

BEGIN

SELECT @PROJECT_NAME = 'KAP';

  BEGIN TRY
 
    --Begin log
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_ARTICLE_DESC_SAP','DW','START';
    EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_DESC_SAP','','MESSAGE','Begin','','';
        	
       EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_DESC_SAP','','MESSAGE','Merge','FILE_ID:',@FILE_ID;
       
       --Update loading table data
			 MERGE INTO DW.D_ARTICLE_DESC_SAP A
			 USING (SELECT MATNR AS SAP_CODE,
			               MAX (CASE
			                      WHEN SPRAS = 'E' THEN MAKTX
			                    END) ARTICLE_DESC,
			               MAX (CASE
			                      WHEN SPRAS = '1' THEN MAKTX
			                    END) CHINESE_DESC
			          FROM STG.STG_MAKT_Material_SAP
			         WHERE MATNR <> ''
			         GROUP BY MATNR) B
			 ON ( A.SAP_MATERIAL = B.SAP_CODE )
			 WHEN MATCHED THEN
			   UPDATE SET A.ARTICLE_DESC = B.ARTICLE_DESC,
			              A.CHINESE_DESC = B.CHINESE_DESC
			 WHEN NOT MATCHED THEN
			   INSERT (SAP_MATERIAL,
			           ARTICLE_DESC,
			           CHINESE_DESC )
			   VALUES (B.SAP_CODE,
			           B.ARTICLE_DESC,
			           B.CHINESE_DESC ); 
 		
 			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_DESC_SAP','','MESSAGE','End','','';
 			
    END TRY

    BEGIN CATCH

        SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
               @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

        SET @v_msg='FILE_ID:'+CAST(@FILE_ID AS VARCHAR(20));

       	EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_DESC_SAP','','EXCEPTION',@v_msg,@errorcode,@errormsg;
    END CATCH
    
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_ARTICLE_DESC_SAP','DW','END';
    
 END

GO
/****** Object:  StoredProcedure [DW].[SP_D_WRF_MATGRP_STRCT_SAP]    Script Date: 3/2/2021 9:17:16 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [DW].[SP_D_WRF_MATGRP_STRCT_SAP] 
AS
	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
 		
  BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_WRF_MATGRP_STRCT_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_WRF_MATGRP_STRCT_SAP', '', 'DW', 'Begin', '', '';
				
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_WRF_MATGRP_STRCT_SAP','','DW','Merge','D_WRF_MATGRP_STRCT_SAP','';
		
		MERGE INTO DW.D_WRF_MATGRP_STRCT_SAP A
		USING STG.STG_WRFMATGRPSTRCT_SAP B
		ON( A.HIER_ID = B.HIER_ID
		    AND A.NODE = B.NODE
		    AND A.SPRAS = B.SPRAS )
		WHEN MATCHED THEN
		  UPDATE SET A.MANDT = B.MANDT,
		  A.LTEXT = B.LTEXT,
		             A.LTEXTG = B.LTEXTG,
		             A.LTEXTLG = B.LTEXTLG
		WHEN NOT MATCHED THEN
		  INSERT( MANDT,
		          HIER_ID,
		          NODE,
		          SPRAS,
		          LTEXT,
		          LTEXTG,
		          LTEXTLG)
		  VALUES(B.MANDT,
		         B.HIER_ID,
		         B.NODE,
		         B.SPRAS,
		         B.LTEXT,
		         B.LTEXTG,
		         B.LTEXTLG); 


 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_WRF_MATGRP_STRCT_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_WRF_MATGRP_STRCT_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_WRF_MATGRP_STRCT_SAP','DW','END';
END

GO
/****** Object:  StoredProcedure [DW].[SP_D_INVENTORY_CLASS_SAP]    Script Date: 3/2/2021 9:14:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [DW].[SP_D_INVENTORY_CLASS_SAP] 
AS
	--DECLARE	@V_MAX_FILE_ID NUMERIC(18,0);
	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
 		
  BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_INVENTORY_CLASS_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_INVENTORY_CLASS_SAP', '', 'DW', 'Begin', '', '';
				
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_INVENTORY_CLASS_SAP','','DW','Merge','D_INVENTORY_CLASS_SAP','';
		
		MERGE INTO DW.D_INVENTORY_CLASS_SAP A
			USING (SELECT T.MATNR           AS SAP_MATERIAL,
			              T.VKORG           AS SALES_ORGANIZATION,
			              T.VTWEG           AS DISTRIBUTION_CHANNEL,
			              T.VMSTA           AS INVENTORY_CLASS_CODE,
			              K.SAP_DESC        AS INVENTORY_CLASS_DESC,
			              A.BRAND,
			              A.BRAND_ID,
			              NULL AS COUNTRY,
			              A.GENERIC_ARTICLE AS LOT_NUMBER
			         FROM STG.STG_MVKE_Material_SAP T
			              LEFT JOIN DW.D_ARTICLE_SIZE_SAP S
			                     ON T.MATNR = S.SAP_MATERIAL
			                        AND S.IS_ACTIVE = 'Y'
			              LEFT JOIN DW.D_ARTICLE_SAP A
			                     ON S.ARTICLE_ID = A.ARTICLE_ID
			              LEFT JOIN DW.D_KEYDATA_SAP K
			                     ON K.CODE_TYPE = 'INVENTORY_CLASS'
			                        AND T.VMSTA = K.SAP_CODE) B
			ON( A.SAP_MATERIAL = B.SAP_MATERIAL
			    AND A.SALES_ORGANIZATION = B.SALES_ORGANIZATION
			    AND A.DISTRIBUTION_CHANNEL = B.DISTRIBUTION_CHANNEL )
			WHEN MATCHED THEN
			  UPDATE SET
			A.INVENTORY_CLASS_CODE = B.INVENTORY_CLASS_CODE,
			A.INVENTORY_CLASS_DESC = B.INVENTORY_CLASS_DESC,
			A.BRAND = B.BRAND,
			A.BRAND_ID = B.BRAND_ID,
			A.COUNTRY = B.COUNTRY,
			A.LOT_NUMBER = B.LOT_NUMBER
			WHEN NOT MATCHED THEN
			  INSERT( SAP_MATERIAL,
			          SALES_ORGANIZATION,
			          DISTRIBUTION_CHANNEL,
			          INVENTORY_CLASS_CODE,
			          INVENTORY_CLASS_DESC,
			          BRAND,
			          BRAND_ID,
			          COUNTRY,
			          LOT_NUMBER)
			  VALUES(B.SAP_MATERIAL,
			         B.SALES_ORGANIZATION,
			         B.DISTRIBUTION_CHANNEL,
			         B.INVENTORY_CLASS_CODE,
			         B.INVENTORY_CLASS_DESC,
			         B.BRAND,
			         B.BRAND_ID,
			         B.COUNTRY,
			         B.LOT_NUMBER); 

 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_INVENTORY_CLASS_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_INVENTORY_CLASS_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_INVENTORY_CLASS_SAP','DW','END';
END

GO



/****** Object:  StoredProcedure [DW].[SP_D_ARTICLE_PRICE_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_ARTICLE_PRICE_SAP] 
	--Load Article Price from LD to DW
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create
AS
DECLARE @v_err_num NUMERIC(18,0);
DECLARE @v_err_msg NVARCHAR(100);
DECLARE @V_SEQ_ID			INTEGER;
DECLARE @V_ARTICLE_NO	NVARCHAR(20);
DECLARE @V_CURRENCY		NVARCHAR(20);
DECLARE @V_CHANNEL			NVARCHAR(20);
DECLARE @V_SALES_ORG		NVARCHAR(20);
DECLARE @V_VALID_TO_DATE	DATE;
DECLARE @PROJECT_NAME varchar(50)
 		
  BEGIN
    SET @PROJECT_NAME = 'KAP';
    
			
  BEGIN TRY
  	EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_ARTICLE_PRICE_SAP','DW','START';
  	EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_PRICE_SAP','','MESSAGE','Begin','','';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_PRICE_SAP','','MESSAGE','MERGE','Load Incremental Data','';
	  
	  MERGE INTO DW.D_ARTICLE_PRICE_SAP A
			USING LD.D_ARTICLE_PRICE_SAP B
			ON ( A.ARTICLE_NO = B.ARTICLE_NO
		       AND A.CURRENCY = B.CURRENCY
		       AND A.CHANNEL = B.CHANNEL
		       AND A.SALES_ORG = B.SALES_ORG
		       AND A.VALID_FROM_DATE = B.VALID_FROM_DATE
			   AND B.VALID_FROM_DATE<B.VALID_TO_DATE)
			WHEN MATCHED THEN
			  UPDATE SET A.VALID_TO_DATE = B.VALID_TO_DATE,
			             A.VALID_FROM_DATE_ID = 0,
			             A.VALID_TO_DATE_ID = 0,
			             A.WHOLESALE_PRICE = B.WHOLESALE_PRICE,
			             A.RETAIL_PRICE = B.RETAIL_PRICE
			WHEN NOT MATCHED THEN
			  INSERT (ARTICLE_NO,
							 	CHANNEL,
							 	SALES_ORG,
							 	CURRENCY,
							 	VALID_FROM_DATE,
							 	VALID_TO_DATE,
							 	VALID_FROM_DATE_ID,
							 	VALID_TO_DATE_ID,
							 	WHOLESALE_PRICE,
							 	RETAIL_PRICE)
			  VALUES (B.ARTICLE_NO,
							  B.CHANNEL,
							  B.SALES_ORG,
							  B.CURRENCY,
							  B.VALID_FROM_DATE,
							  B.VALID_TO_DATE,
							  0,
							  0,
							  B.WHOLESALE_PRICE,
							  B.RETAIL_PRICE);
	  
	  	  
	 EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_PRICE_SAP','','MESSAGE','UPDATE','Invalid End Date','';


	 MERGE INTO DW.D_ARTICLE_PRICE_SAP A
	 USING (SELECT CHANNEL,
	   						 SALES_ORG,
	   						 ARTICLE_NO,
	   						 CURRENCY,
	   						 VALID_FROM_DATE,
	   						 SEQ_ID,
	   						 ISNULL(DATEADD(DAY,-1,LEAD(VALID_FROM_DATE) OVER (PARTITION BY CHANNEL,SALES_ORG,ARTICLE_NO,CURRENCY ORDER BY VALID_FROM_DATE)),
	   						 				'9999-12-31') AS V_VALID_TO_DATE
	   				FROM DW.D_ARTICLE_PRICE_SAP) B
	  ON A.SEQ_ID = B.SEQ_ID
	 WHEN MATCHED THEN
				  UPDATE SET VALID_TO_DATE = V_VALID_TO_DATE,
							 VALID_TO_DATE_ID = 0;

	  
	  	  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_PRICE_SAP','','MESSAGE','UPDATE','DATE_ID','';
	  
		UPDATE A
		  SET A.VALID_FROM_DATE_ID = ISNULL (B.DATE_ID, 0)
		FROM DW.D_ARTICLE_PRICE_SAP A
		LEFT JOIN DW.D_DATE B
			ON B.DAY_DATE = A.VALID_FROM_DATE
		WHERE A.VALID_FROM_DATE_ID = 0;			
		
		UPDATE A
		  SET A.VALID_TO_DATE_ID = ISNULL (B.DATE_ID, 99999999)
		FROM DW.D_ARTICLE_PRICE_SAP A
		LEFT JOIN DW.D_DATE B
			ON B.DAY_DATE = A.VALID_TO_DATE
		WHERE A.VALID_TO_DATE_ID = 0;
				                          
		
				EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_ARTICLE_PRICE_SAP', '', 'MESSAGE', 'End', '', '';
END TRY
BEGIN CATCH
			SET @v_err_num = ERROR_NUMBER();
			SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
			
	EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_ARTICLE_PRICE_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
	
END CATCH
	EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_ARTICLE_PRICE_SAP','DW','END';
END


GO
/****** Object:  StoredProcedure [DW].[SP_D_ARTICLE_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_ARTICLE_SAP]
  --Load data from loading to DATAMARTS
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create

AS

    DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @PROJECT_NAME varchar(50)
    DECLARE @FILE_ID INT

BEGIN
	
	SET @PROJECT_NAME = 'KAP';
	
    BEGIN TRY
    		--Begin log
    		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_ARTICLE_SAP','DM','START';
        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_ARTICLE_SAP', '', 'MESSAGE', 'Begin', '', '';
				
				UPDATE DW.D_ARTICLE_SAP
				SET IS_ACTIVE = 'N'
				WHERE GENERIC_ARTICLE IN (SELECT GENERIC_ARTICLE FROM LD.LD_ARTICLE_SAP WHERE GENERIC_ARTICLE = C1_0MATERIAL);
				
        --Update loading table data
    		MERGE INTO DW.D_ARTICLE_SAP A
    		     USING (SELECT  B1.GENERIC_ARTICLE,
    		                    B1.MERCHANDISE_CATEGORY_CODE,
    		                    B1.MERCHANDISE_CATEGORY_DESCR,
    		                    B1.MC_DESCRIPTION_IN_CH,
    		                    B1.ARTICLE_DESC,
    		                    B1.CHINESE_DESC,
    		                    B1.CURRENT_SEASON,
    		                    B1.CURRENT_YEAR,
    		                    B1.BRAND_ID,
    		                    B1.STYLE,
    		                    B1.BIRTH,
    		                    B1.BIRTH_YEAR,
    		                    B1.DC_BILL_CATEGORY,
    		                    B1.ABM_TIER_D,
    		                    B1.COLOR_CODE,
    		                    B1.GENDER_CODE,
    		                    B1.LOCAL_GENDER,
    		                    B1.COLLECTION AS SERIES,
    		                    B1.DESIGN_OFFICE,
    		                    B1.MARKETING_CAMPAIGN,
    		                    B1.CN_RETAIL_CATEGORY,
    		                    B1.CN_RETAIL_PRODUCT_TYPE,
    		                    B1.TNF_TOP_BOTTOM,
    		                    B1.COLOR_GROUP,
    		                    B1.COLOR_DESC,
    		                    B1.SBU_CODE,
    		                    B1.PRODUCT_GROUP AS SBU_DESC,
    		                    B1.PRODUCT_SUB_GROUP AS SBU_SUB_DESC,
    		                    B1.ITCGROUP,
    		                    B1.PRODUCT_LAUNCH_DATE,
    		                    B1.RETAIL_PRICE,
    		                    B1.FABRIC_CODE,
    		                    B1.FABRIC_DESC,
    		                    B1.MATERIAL_CODE,
    		                    B1.RISE,
    		                    B1.LEG,
    		                    B1.FIT,
    		                    B1.COLLECTION,
    		                    B1.BRAND,
    		                    B1.SBU_SUB_CODE,
    		                    B1.SAP_ARTICLE_NUMBER,
    		                    B1.INVENTORY_CLASS,
    		                    B1.PRODUCT_TYPE,
    		                    B1.MODE,
    		                    B1.ARTICLE_TYPE,
    		                    B1.SEASON_STATUS,
    		                    B1.LOCAL_SEASON,
    		                    B1.LOCAL_LAUNCH_DATE,
    		                    B1.COLLECTION_DESC,
    		                    B1.LOCAL_COLOR_DESC,
    		                    B1.PRODUCT_TYPE2,
    		                    B1.PRICE_BAND_CATEGORY,
    		                    B1.LOCAL_GENDER_DESC,
    		                    B1.GENDER_DESC,
    		                    B1.LOCAL_GENDER_CN,
    		                    B1.TEXTILE_MATERIAL_CATEGORY_DESC,
    		                    B1.DESIGN_DESC,
    		                    B1.FUNCTION_TECHNOLOGY,
    		                    B1.FILLING_DESC,
    		                    B1.UPPER_MATERIAL_DESC,
    		                    B1.MATERIALS_CN,
    		                    B1.WEIGHT_DESC,
    		                    B1.WEIGHT,
    		                    B1.FIT_NUMBER,
    		                    B1.MARKETING_CAMPAIGN_NAME,
    		                    B1.EVENT_DESC,
    		                    B1.CN_RETAIL_PRODUCT_TYPE_DESC,
    		      							B1.SOURCING_LOCATION,
    		                    B1.SOURCING_LOCATION_DESC,
    		                    B1.COUNTRY_OF_ORIGIN,
    		                    B1.DEVELOP_OFFICE,
    		                    B1.SIZE_REGION,
    		                    B1.ITEM_MARK_FOR,
    		                    B1.ITEM_MARK_FOR_DESC,
    		                    B1.NECK_LINE,
    		                    B1.SIZE_RANGE_FOR_CHINA,
    		                    B1.PRICE_POINT,
    		                    B1.BASE_UNIT_OF_MEASURE,
    		                    B1.AP_ONLY,
    		                    B1.BUYING_GUIDELINE,
    		                    B1.US_RETAIL_PRICE,
    		                  	B1.SUB_CLASS,
    		       							B1.TQ_ID,
    		                    B1.DYO_ID,
    		                    B1.ORDER_SEASON,
    		                    B1.QUALITY_ID,
    		                    B1.EXT_MC_CODE,
    		                    B1.RETAIL_LAST_SEASON,
    		                    B1.SBU_DESC_CN,
    		                    B1.SBU_SUB_DESC_CN,
    		                    B1.LAST_MODIFIED_TIME,
    		                    B1.SEASON_EFFECTIVE_DATE,
    		                    B1.TBL_CATEGORY,
    		                    B1.AGE_GROUP,
    		                    B1.DIVISION,
    		                    B1.SAP_GENDER_DESC,
    		                    B1.COLOR_GROUP_DESC,
    		                    M.OLD_ARTICLE AS OLD_GENERIC_ARTICLE,
    		                    B1.OLD_MERCHANDISE_CATEGORY_CODE,
    		                    B1.OLD_MERCHANDISE_CATEGORY_DESCR,
    		                    B1.CN_LAB_TEST,
    		                    B1.MATERIAL_GROUP,
														B1.PRODUCT_GROUP,
														B1.PRODUCT_SUB_GROUP,
														B1.SUB_BRAND,
														B1.CONCEPT,
														B1.STORY,
														B1.TIER,
    		                    ISNULL(PRODUCT_GROUP,'NA') AS CATEGORY_CRM,
    		                    ISNULL(CASE WHEN BRAND_ID = 2 THEN PRODUCT_SUB_GROUP 
    		                         ELSE MERCHANDISE_CATEGORY_DESCR 
    		                    END,'NA') AS CLASS_CRM,
    		                    ISNULL(CASE WHEN BRAND_ID = 2 THEN PRODUCT_SUB_GROUP  
    		                         ELSE SUB_CLASS 
    		                    END,'NA') AS SUB_CLASS_CRM,
    		                    ISNULL(PRODUCT_GROUP,'NA') AS RETAIL_CATEGORY
    		            FROM (SELECT T.*, ROW_NUMBER() OVER(PARTITION BY T.GENERIC_ARTICLE, T.CURRENT_YEAR, T.CURRENT_SEASON ORDER BY T.C1_0MATERIAL) RID      
    		            			 FROM LD.LD_ARTICLE_SAP T
													 WHERE T.GENERIC_ARTICLE = T.C1_0MATERIAL) B1
										LEFT JOIN DW.D_ARTICLE_MAPPING M
											ON B1.GENERIC_ARTICLE = M.NEW_ARTICLE
									 WHERE B1.RID = 1
							) B
    		    ON (A.GENERIC_ARTICLE = B.GENERIC_ARTICLE AND A.CURRENT_SEASON = B.CURRENT_SEASON  AND A.CURRENT_YEAR = B.CURRENT_YEAR)
    		    WHEN MATCHED THEN UPDATE
    		        SET --GENERIC_ARTICLE                 = B.GENERIC_ARTICLE,
    		            MERCHANDISE_CATEGORY_CODE       = B.MERCHANDISE_CATEGORY_CODE,
    		            --MERCHANDISE_CATEGORY_DESCR      = B.MERCHANDISE_CATEGORY_DESCR,
    		            --MC_DESCRIPTION_IN_CH            = B.MC_DESCRIPTION_IN_CH,
    		            ARTICLE_DESC                    = B.ARTICLE_DESC,
    		            CHINESE_DESC                    = B.CHINESE_DESC,
    		            --CURRENT_SEASON                  = B.CURRENT_SEASON,
    		            --CURRENT_YEAR                    = B.CURRENT_YEAR,
    		            BRAND_ID                        = B.BRAND_ID,
    		            --STYLE                           = B.STYLE,
    		            BIRTH                           = B.BIRTH,
    		            BIRTH_YEAR                      = B.BIRTH_YEAR,
    		            --DC_BILL_CATEGORY             = B.DC_BILL_CATEGORY,
    		            --ABM_TIER_D                      = B.ABM_TIER_D,
    		            COLOR_CODE                      = B.COLOR_CODE,
    		            GENDER_CODE                     = B.GENDER_CODE,
    		            --LOCAL_GENDER                    = B.LOCAL_GENDER,
    		            SERIES                          = B.SERIES,
    		            DESIGN_OFFICE                   = B.DESIGN_OFFICE,
    		            --MARKETING_CAMPAIGN              = B.MARKETING_CAMPAIGN,
    		            --CN_RETAIL_CATEGORY              = B.CN_RETAIL_CATEGORY,
    		            --CN_RETAIL_PRODUCT_TYPE          = B.CN_RETAIL_PRODUCT_TYPE,
    		            --TNF_TOP_BOTTOM                  = B.TNF_TOP_BOTTOM,
    		            --COLOR_GROUP                     = B.COLOR_GROUP,
    		            --COLOR_DESC                      = B.COLOR_DESC,
    		            --SBU_CODE                        = B.SBU_CODE,
    		            SBU_DESC                        = B.SBU_DESC,
    		            SBU_SUB_DESC                    = B.SBU_SUB_DESC,
    		            --ITCGROUP                        = B.ITCGROUP,
    		            --PRODUCT_LAUNCH_DATE             = B.PRODUCT_LAUNCH_DATE,
    		            --RETAIL_PRICE                    = B.RETAIL_PRICE,
    		            --FABRIC_CODE                     = B.FABRIC_CODE,
    		            --FABRIC_DESC                     = B.FABRIC_DESC,
    		            --MATERIAL_CODE                   = B.MATERIAL_CODE,
    		            --RISE                            = B.RISE,
    		            --LEG                             = B.LEG,
    		            --FIT                             = B.FIT,
    		            COLLECTION                      = B.COLLECTION,
    		            BRAND                           = B.BRAND,
    		            --SBU_SUB_CODE                    = B.SBU_SUB_CODE,
    		            --SAP_ARTICLE_NUMBER              = B.SAP_ARTICLE_NUMBER,
    		            --INVENTORY_CLASS                 = B.INVENTORY_CLASS,
    		            --PRODUCT_TYPE                    = B.PRODUCT_TYPE,
    		            --IS_CUSTOMS                    	= B.IS_CUSTOMS,     
    		            --IS_UGC													= B.IS_UGC,
    		            --MODE                            = B.MODE,
    		            ARTICLE_TYPE                    = B.ARTICLE_TYPE,
    		            --SEASON_STATUS                   = B.SEASON_STATUS,
    		            --LOCAL_SEASON                    = B.LOCAL_SEASON,
    		            --LOCAL_LAUNCH_DATE               = B.LOCAL_LAUNCH_DATE,
    		            --COLLECTION_DESC                 = B.COLLECTION_DESC,
    		            --LOCAL_COLOR_DESC                = B.LOCAL_COLOR_DESC,
    		            --PRODUCT_TYPE2                   = B.PRODUCT_TYPE2,
    		            PRICE_BAND_CATEGORY             = B.PRICE_BAND_CATEGORY,
    		            --LOCAL_GENDER_DESC               = B.LOCAL_GENDER_DESC,
    		            --GENDER_DESC                     = B.GENDER_DESC,
    		            --LOCAL_GENDER_CN                 = B.LOCAL_GENDER_CN,
    		            --TEXTILE_MATERIAL_CATEGORY_DESC  = B.TEXTILE_MATERIAL_CATEGORY_DESC,
    		            --DESIGN_DESC                     = B.DESIGN_DESC,
    		            --FUNCTION_TECHNOLOGY             = B.FUNCTION_TECHNOLOGY,
    		            FILLING_DESC                    = B.FILLING_DESC,
    		            --UPPER_MATERIAL_DESC             = B.UPPER_MATERIAL_DESC,
    		            --MATERIALS_CN                    = B.MATERIALS_CN,
    		            --WEIGHT_DESC                     = B.WEIGHT_DESC,
    		            --WEIGHT                          = B.WEIGHT,
    		            --FIT_NUMBER                      = B.FIT_NUMBER,
    		            --MARKETING_CAMPAIGN_NAME         = B.MARKETING_CAMPAIGN_NAME,
    		            --EVENT_DESC                      = B.EVENT_DESC,
    		            --CN_RETAIL_PRODUCT_TYPE_DESC     = B.CN_RETAIL_PRODUCT_TYPE_DESC,
    		            --SOURCING_LOCATION               = B.SOURCING_LOCATION,
    		            --SOURCING_LOCATION_DESC          = B.SOURCING_LOCATION_DESC,
    		            --COUNTRY_OF_ORIGIN               = B.COUNTRY_OF_ORIGIN,
    		            --DEVELOP_OFFICE                  = B.DEVELOP_OFFICE,
    		            --SIZE_REGION                     = B.SIZE_REGION,
    		            --ITEM_MARK_FOR                   = B.ITEM_MARK_FOR,
    		            --ITEM_MARK_FOR_DESC              = B.ITEM_MARK_FOR_DESC,
    		            --NECK_LINE                       = B.NECK_LINE,
    		            --SIZE_RANGE_FOR_CHINA            = B.SIZE_RANGE_FOR_CHINA,
    		            --PRICE_POINT                     = B.PRICE_POINT,
    		            BASE_UNIT_OF_MEASURE            = B.BASE_UNIT_OF_MEASURE,
    		            --AP_ONLY                         = B.AP_ONLY,
    		            --BUYING_GUIDELINE                = B.BUYING_GUIDELINE,
    		            --US_RETAIL_PRICE                 = B.US_RETAIL_PRICE,
    		            --SUB_CLASS                       = B.SUB_CLASS,
    		            --TQ_ID                           = B.TQ_ID,
    		            --DYO_ID                          = B.DYO_ID,
    		            --ORDER_SEASON                    = B.ORDER_SEASON,
    		            --QUALITY_ID                      = B.QUALITY_ID,
    		            --EXT_MC_CODE                     = B.EXT_MC_CODE,
    		            --RETAIL_LAST_SEASON              = B.RETAIL_LAST_SEASON,
    		            --SBU_DESC_CN                     = B.SBU_DESC_CN,
    		            --SBU_SUB_DESC_CN                 = B.SBU_SUB_DESC_CN,
    		            --LAST_MODIFIED_TIME              = B.LAST_MODIFIED_TIME,
    		            --SEASON_EFFECTIVE_DATE           = B.SEASON_EFFECTIVE_DATE,
    		            --TBL_CATEGORY                    = B.TBL_CATEGORY,
    		            --AGE_GROUP                       = B.AGE_GROUP,
    		            DIVISION                        = B.DIVISION,
    		            SAP_GENDER_DESC                 = B.SAP_GENDER_DESC,
    		            --COLOR_GROUP_DESC                = B.COLOR_GROUP_DESC,
    		            OLD_GENERIC_ARTICLE             = B.OLD_GENERIC_ARTICLE,
    		            --OLD_MERCHANDISE_CATEGORY_CODE   = B.OLD_MERCHANDISE_CATEGORY_CODE,
    		            --OLD_MERCHANDISE_CATEGORY_DESCR  = B.OLD_MERCHANDISE_CATEGORY_DESCR,
    		            --CN_LAB_TEST                     = B.CN_LAB_TEST,
    		            CATEGORY_CRM                    = B.CATEGORY_CRM,
    		            CLASS_CRM                       = B.CLASS_CRM,
    		            SUB_CLASS_CRM                   = B.SUB_CLASS_CRM,
    		            RETAIL_CATEGORY									= B.RETAIL_CATEGORY,
    		            IS_ACTIVE                       = 'Y',
    		            MATERIAL_GROUP									= B.MATERIAL_GROUP,
    		            PRODUCT_GROUP									= B.PRODUCT_GROUP,
    		            PRODUCT_SUB_GROUP									= B.PRODUCT_SUB_GROUP,
    		            SUB_BRAND									= B.SUB_BRAND,
    		            CONCEPT									= B.CONCEPT,
    		            STORY									= B.STORY,
    		            TIER									= B.TIER
    		    WHEN NOT MATCHED THEN INSERT (
    		            GENERIC_ARTICLE,
    		            MERCHANDISE_CATEGORY_CODE,
    		            MERCHANDISE_CATEGORY_DESCR,
    		            MC_DESCRIPTION_IN_CH,
    		            ARTICLE_DESC,
    		            CHINESE_DESC,
    		            CURRENT_SEASON,
    		            CURRENT_YEAR,
    		            BRAND_ID,
    		            STYLE,
    		            BIRTH,
    		            BIRTH_YEAR,
    		            DC_BILL_CATEGORY,
    		            ABM_TIER_D,
    		            COLOR_CODE,
    		            GENDER_CODE,
    		            LOCAL_GENDER,
    		            SERIES,
    		            DESIGN_OFFICE,
    		            MARKETING_CAMPAIGN,
    		            CN_RETAIL_CATEGORY,
    		            CN_RETAIL_PRODUCT_TYPE,
    		            TNF_TOP_BOTTOM,
    		            COLOR_GROUP,
    		            COLOR_DESC,
    		            SBU_CODE,
    		            SBU_DESC,
    		            SBU_SUB_DESC,
    		            ITCGROUP,
    		            PRODUCT_LAUNCH_DATE,
    		            RETAIL_PRICE,
    		            FABRIC_CODE,
    		            FABRIC_DESC,
    		            MATERIAL_CODE,
    		            RISE,
    		            LEG,
    		            FIT,
    		            COLLECTION,
    		            BRAND,
    		            SBU_SUB_CODE,
    		            SAP_ARTICLE_NUMBER,
    		            INVENTORY_CLASS,
    		            PRODUCT_TYPE,
    		            --IS_CUSTOMS,   
    		            --IS_UGC,
    		            MODE,
    		            ARTICLE_TYPE,
    		            SEASON_STATUS,
    		            LOCAL_SEASON,
    		            LOCAL_LAUNCH_DATE,
    		            COLLECTION_DESC,
    		            LOCAL_COLOR_DESC,
    		            PRODUCT_TYPE2,
    		            PRICE_BAND_CATEGORY,
    		            LOCAL_GENDER_DESC,
    		            GENDER_DESC,
    		            LOCAL_GENDER_CN,
    		            TEXTILE_MATERIAL_CATEGORY_DESC,
    		            DESIGN_DESC,
    		            FUNCTION_TECHNOLOGY,
    		            FILLING_DESC,
    		            UPPER_MATERIAL_DESC,
    		            MATERIALS_CN,
    		            WEIGHT_DESC,
    		            WEIGHT,
    		            FIT_NUMBER,
    		            MARKETING_CAMPAIGN_NAME,
    		            EVENT_DESC,
    		            CN_RETAIL_PRODUCT_TYPE_DESC,
    		            SOURCING_LOCATION,
    		            SOURCING_LOCATION_DESC,
    		            COUNTRY_OF_ORIGIN,
    		            DEVELOP_OFFICE,
    		            SIZE_REGION,
    		            ITEM_MARK_FOR,
    		            ITEM_MARK_FOR_DESC,
    		            NECK_LINE,
    		            SIZE_RANGE_FOR_CHINA,
    		            PRICE_POINT,
    		            BASE_UNIT_OF_MEASURE,
    		            AP_ONLY,
    		            BUYING_GUIDELINE,
    		            US_RETAIL_PRICE,
    		            SUB_CLASS,
    		            TQ_ID,
    		            DYO_ID,
    		            ORDER_SEASON,
    		            QUALITY_ID,
    		            EXT_MC_CODE,
    		            RETAIL_LAST_SEASON,
    		            SBU_DESC_CN,
    		            SBU_SUB_DESC_CN,
    		            LAST_MODIFIED_TIME,
    		            SEASON_EFFECTIVE_DATE,
    		            TBL_CATEGORY,
    		            AGE_GROUP,
    		            DIVISION,
    		            SAP_GENDER_DESC,
    		            COLOR_GROUP_DESC,
    		            OLD_GENERIC_ARTICLE,
    		            OLD_MERCHANDISE_CATEGORY_CODE,
    		            OLD_MERCHANDISE_CATEGORY_DESCR,
    		            CN_LAB_TEST,
    		            CATEGORY_CRM,
    		            CLASS_CRM,
    		            SUB_CLASS_CRM,
    		            RETAIL_CATEGORY,
    		            IS_ACTIVE,
    		            MATERIAL_GROUP,
										PRODUCT_GROUP,
										PRODUCT_SUB_GROUP,
										SUB_BRAND,
										CONCEPT,
										STORY,
										TIER)
    		    VALUES (B.GENERIC_ARTICLE,
    		            B.MERCHANDISE_CATEGORY_CODE,
    		            B.MERCHANDISE_CATEGORY_DESCR,
    		            B.MC_DESCRIPTION_IN_CH,
    		            B.ARTICLE_DESC,
    		            B.CHINESE_DESC,
    		            B.CURRENT_SEASON,
    		            B.CURRENT_YEAR,
    		            B.BRAND_ID,
    		            B.STYLE,
    		            B.BIRTH,
    		            B.BIRTH_YEAR,
    		            B.DC_BILL_CATEGORY,
    		            B.ABM_TIER_D,
    		            B.COLOR_CODE,
    		            B.GENDER_CODE,
    		            B.LOCAL_GENDER,
    		            B.SERIES,
    		            B.DESIGN_OFFICE,
    		            B.MARKETING_CAMPAIGN,
    		            B.CN_RETAIL_CATEGORY,
    		            B.CN_RETAIL_PRODUCT_TYPE,
    		            B.TNF_TOP_BOTTOM,
    		            B.COLOR_GROUP,
    		            B.COLOR_DESC,
    		            B.SBU_CODE,
    		            B.SBU_DESC,
    		            B.SBU_SUB_DESC,
    		            B.ITCGROUP,
    		            B.PRODUCT_LAUNCH_DATE,
    		            B.RETAIL_PRICE,
    		            B.FABRIC_CODE,
    		            B.FABRIC_DESC,
    		            B.MATERIAL_CODE,
    		            B.RISE,
    		            B.LEG,
    		            B.FIT,
    		            B.COLLECTION,
    		            B.BRAND,
    		            B.SBU_SUB_CODE,
    		            B.SAP_ARTICLE_NUMBER,
    		            B.INVENTORY_CLASS,
    		            B.PRODUCT_TYPE,
    		            --B.IS_CUSTOMS,
    		            --B.IS_UGC,
    		            B.MODE,
    		            B.ARTICLE_TYPE,
    		            B.SEASON_STATUS,
    		            B.LOCAL_SEASON,
    		            B.LOCAL_LAUNCH_DATE,
    		            B.COLLECTION_DESC,
    		            B.LOCAL_COLOR_DESC,
    		            B.PRODUCT_TYPE2,
    		            B.PRICE_BAND_CATEGORY,
    		            B.LOCAL_GENDER_DESC,
    		            B.GENDER_DESC,
    		            B.LOCAL_GENDER_CN,
    		            B.TEXTILE_MATERIAL_CATEGORY_DESC,
    		            B.DESIGN_DESC,
    		            B.FUNCTION_TECHNOLOGY,
    		            B.FILLING_DESC,
    		            B.UPPER_MATERIAL_DESC,
    		            B.MATERIALS_CN,
    		            B.WEIGHT_DESC,
    		            B.WEIGHT,
    		            B.FIT_NUMBER,
    		            B.MARKETING_CAMPAIGN_NAME,
    		            B.EVENT_DESC,
    		            B.CN_RETAIL_PRODUCT_TYPE_DESC,
    		            B.SOURCING_LOCATION,
    		            B.SOURCING_LOCATION_DESC,
    		            B.COUNTRY_OF_ORIGIN,
    		            B.DEVELOP_OFFICE,
    		            B.SIZE_REGION,
    		            B.ITEM_MARK_FOR,
    		            B.ITEM_MARK_FOR_DESC,
    		            B.NECK_LINE,
    		            B.SIZE_RANGE_FOR_CHINA,
    		            B.PRICE_POINT,
    		            B.BASE_UNIT_OF_MEASURE,
    		            B.AP_ONLY,
    		            B.BUYING_GUIDELINE,
    		            B.US_RETAIL_PRICE,
    		      			B.SUB_CLASS,
    		            B.TQ_ID,
    		            B.DYO_ID,
    		            B.ORDER_SEASON,
    		            B.QUALITY_ID,
    		            B.EXT_MC_CODE,
    		            B.RETAIL_LAST_SEASON,
    		            B.SBU_DESC_CN,
    		            B.SBU_SUB_DESC_CN,
    		            B.LAST_MODIFIED_TIME,
    		            B.SEASON_EFFECTIVE_DATE,
    		            B.TBL_CATEGORY,
    		            B.AGE_GROUP,
    		            B.DIVISION,
    		            B.SAP_GENDER_DESC,
    		            B.COLOR_GROUP_DESC,
    		            B.OLD_GENERIC_ARTICLE,
    		            B.OLD_MERCHANDISE_CATEGORY_CODE,
    		            B.OLD_MERCHANDISE_CATEGORY_DESCR,
    		            B.CN_LAB_TEST,
    		            B.CATEGORY_CRM,
    		            B.CLASS_CRM,
    		            B.SUB_CLASS_CRM,
    		            B.RETAIL_CATEGORY,
    		            'Y',
    		            B.MATERIAL_GROUP,
										B.PRODUCT_GROUP,
										B.PRODUCT_SUB_GROUP,
										B.SUB_BRAND,
										B.CONCEPT,
										B.STORY,
										B.TIER);       
				
				EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_ARTICLE_SAP', '', 'Update', 'SELLING_SEASON', '', '';
				
				UPDATE T
				   SET SELLING_SEASON_YEAR = S.FSH_SEASON_YEAR,
				       SELLING_SEASON = S.FSH_SEASON
				  FROM DW.D_ARTICLE_SAP T
				       LEFT JOIN DW.D_FSHSEASONSMAT_SAP S
				              ON S.SEASON2 = 'X'
				                 AND T.GENERIC_ARTICLE = S.MATNR; 
				
				UPDATE DW.D_ARTICLE_SIZE_SAP
				   SET IS_ACTIVE = 'N'
				 WHERE IS_ACTIVE = 'Y'
				       AND SAP_MATERIAL IN (SELECT S.C1_0MATERIAL
				                              FROM LD.LD_ARTICLE_SAP S
				                             WHERE S.GENERIC_ARTICLE <> S.C1_0MATERIAL);
				
        MERGE INTO DW.D_ARTICLE_SIZE_SAP A
         USING (SELECT C1_0MATERIAL,
                       T.GENERIC_ARTICLE,
                       CURRENT_YEAR,
                       CURRENT_SEASON,
                       C68_0RT_SIZE,
                       C52_0RF_SIZE2,
                       C19_0EANUPC,
                       ARTICLE_DESC AS MATERIAL_DESC_EN,
                       CHINESE_DESC AS MATERIAL_DESC_CN
                  FROM LD.LD_ARTICLE_SAP T
                 WHERE T.GENERIC_ARTICLE <> T.C1_0MATERIAL) B
            ON (A.SAP_MATERIAL = B.C1_0MATERIAL
						--AND A.GENERIC_ARTICLE = B.GENERIC_ARTICLE
            AND A.CURRENT_YEAR = B.CURRENT_YEAR
            AND A.CURRENT_SEASON = B.CURRENT_SEASON)
        WHEN MATCHED
        THEN
           UPDATE SET GENERIC_ARTICLE = B.GENERIC_ARTICLE,
                      DIM1 = B.C68_0RT_SIZE,
                      DIM2 = B.C52_0RF_SIZE2,
                      EAN_UPC = B.C19_0EANUPC,
                      MATERIAL_DESC_EN = B.MATERIAL_DESC_EN,
                      MATERIAL_DESC_CN = B.MATERIAL_DESC_CN,
                      IS_ACTIVE = 'Y',
                      UPDATED_AT = GETDATE()
        WHEN NOT MATCHED
        THEN
           INSERT (SAP_MATERIAL,
                   GENERIC_ARTICLE,
                   CURRENT_YEAR,
                   CURRENT_SEASON,
                   DIM1,
                   DIM2,
                   EAN_UPC,
                   MATERIAL_DESC_EN,
                   MATERIAL_DESC_CN,
                   IS_ACTIVE,
                   CREATED_AT,
                   UPDATED_AT)
           VALUES (B.C1_0MATERIAL,
                   B.GENERIC_ARTICLE,
                   B.CURRENT_YEAR,
                   B.CURRENT_SEASON,
                   B.C68_0RT_SIZE,
                   B.C52_0RF_SIZE2,
                   B.C19_0EANUPC,
                   B.MATERIAL_DESC_EN,
                   B.MATERIAL_DESC_CN,
                   'Y',
                   GETDATE(),
                   GETDATE());
                
        UPDATE DW.D_ARTICLE_SIZE_SAP
        SET ARTICLE_ID = B.ARTICLE_ID
        FROM DW.D_ARTICLE_SAP B
        RIGHT JOIN DW.D_ARTICLE_SIZE_SAP A
        ON A.GENERIC_ARTICLE = B.GENERIC_ARTICLE
        AND A.CURRENT_YEAR = B.CURRENT_YEAR
        AND A.CURRENT_SEASON = B.CURRENT_SEASON
        WHERE A.ARTICLE_ID IS NULL;
        
        DELETE FROM DW.D_ARTICLE_SIZE_SAP WHERE ARTICLE_ID IS NULL;

        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_ARTICLE_SAP', '', 'MESSAGE', 'End', '', '';
        
        END TRY

            BEGIN CATCH
             

                SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
                       @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

                SET @v_msg='FILE_ID:'+CAST(@FILE_ID AS VARCHAR(20));

                EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_ARTICLE_SAP', '', 'EXCEPTION', @v_msg, @errorcode, @errormsg;
                
            END CATCH
            
         EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_ARTICLE_SAP','DM','END';
    END



GO

/****** Object:  StoredProcedure [DW].[SP_D_CUSTOMER_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_CUSTOMER_SAP] 
AS
	--DECLARE	@V_MAX_FILE_ID NUMERIC(18,0);
	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @NAME1 NVARCHAR(100);
	DECLARE @NAME2 NVARCHAR(100);
	DECLARE @NAME3 NVARCHAR(100);
	DECLARE @COUNTRY NVARCHAR(100);
	DECLARE @CUSTOMER NVARCHAR(100);
	DECLARE @TEMP NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
 		
  BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_CUSTOMER_SAP','DM','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_CUSTOMER_SAP', '', 'DW', 'Begin', '', '';
				
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_CUSTOMER_SAP','','DW','Merge','D_CUSTOMER_SAP','';
			
		MERGE INTO DW.D_CUSTOMER_SAP A
		USING (SELECT T.*
						 FROM (SELECT STUFF(K.KUNNR, 1, PATINDEX ('%[^0]%', K.KUNNR) - 1, '') AS CUSTOMER_CODE,
		         				      ISNULL(B.NAME1, K.NAME1)                                AS NAME_CN,
		         				      K.NAME1                                                 AS NAME_EN,
		         				      K.ORT01                                                 AS CITY,
		         				      K.LAND1                                                 AS COUNTRY,
		         				      K.REGIO                                                 AS REGION,
		         				      K.ADRNR                                                 AS [ADDRESS],
		         				      K.NAME1,
		         				      K.NAME2,
		         				      K.NAME3,
		         				      K.KONZS                                                 AS CUSTOMER_GROUP,
		         				      K.WERKS                                                 AS PLANT,
		         				      K.KATR1                                                 AS PLANT_TYPE,
		         				      CASE
		         				        WHEN K.WERKS <> '' THEN A.SORT2
		         				        ELSE ''
		         				      END                                                     AS OLD_PLANT,
		         				      ROW_NUMBER()
		         				        OVER(
		         				          PARTITION BY K.KUNNR
		         				          ORDER BY A.DATE_FROM)                               RID
		         				 FROM STG.STG_KNA1_Customer_SAP K
		         				      LEFT JOIN STG.STG_ADRC_Address_SAP A
		         				             ON K.ADRNR = A.ADDRNUMBER
		         				      LEFT JOIN STG.STG_ADRC_Address_SAP B
		         				             ON K.ADRNR = B.ADDRNUMBER
		         				             		AND B.NATION = 'C') T
		         				 WHERE T.RID = 1) B
		ON ( A.CUSTOMER_CODE = B.CUSTOMER_CODE )
		WHEN MATCHED THEN
		  UPDATE SET A.NAME_CN = B.NAME_CN,
		             A.NAME_EN = B.NAME_EN,
		             A.CITY = B.CITY,
		             A.COUNTRY = B.COUNTRY,
		             A.REGION = B.REGION,
		             A.[ADDRESS] = B.[ADDRESS],
		             A.NAME1 = B.NAME1,
		             A.NAME2 = B.NAME2,
		             A.NAME3 = B.NAME3,
		             A.CUSTOMER_GROUP = B.CUSTOMER_GROUP,
		             A.PLANT = B.PLANT,
		             A.PLANT_TYPE = B.PLANT_TYPE,
		             A.OLD_PLANT = B.OLD_PLANT
		WHEN NOT MATCHED THEN
		  INSERT ( CUSTOMER_CODE,
		           NAME_CN,
		           NAME_EN,
		           CITY,
		           COUNTRY,
		           REGION,
		           [ADDRESS],
		           NAME1,
		           NAME2,
		           NAME3,
		           CUSTOMER_GROUP,
		           PLANT,
		           PLANT_TYPE,
		           OLD_PLANT)
		  VALUES ( B.CUSTOMER_CODE,
		           B.NAME_CN,
		           B.NAME_EN,
		           B.CITY,
		           B.COUNTRY,
		           B.REGION,
		           B.[ADDRESS],
		           B.NAME1,
		           B.NAME2,
		           B.NAME3,
		           B.CUSTOMER_GROUP,
		           B.PLANT,
		           B.PLANT_TYPE,
		           B.OLD_PLANT); 


 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_CUSTOMER_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_CUSTOMER_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_CUSTOMER_SAP','DM','END';
END

GO
/****** Object:  StoredProcedure [DW].[SP_D_DATE_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [DW].[SP_D_DATE_SAP]
  --Load data from loading to datamarts
  --Created by   : Daniel
  --Version       : 1.0
  --Modify History: Create

  
AS

    DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @PROJECT_NAME varchar(50)
    DECLARE @V_WEEKCOUNT     INT;
    DECLARE @V_CUR_DATE      DATE;       --Sysdate-1 of Beijing Time Zone
    DECLARE @V_WFD           DATE;       --Start Date Of This Week
    DECLARE @V_MFD           DATE;       --Start Date Of This Month
    DECLARE @V_LM_MFD        DATE;       --Start Date Of Last Month
    DECLARE @V_L2M_MFD       DATE;       --Start Date Of 2 Month Before
    DECLARE @V_L3M_MFD       DATE;       --Start Date Of 3 Month Before
    DECLARE @V_L4M_MFD       DATE;       --Start Date Of 4 Month Before
    DECLARE @V_QFD           DATE;       --Start Date Of This Quarter
    DECLARE @V_YFD           DATE;       --Start Date Of This Year
    DECLARE @V_LY_CUR_DATE   DATE;       --Current Date Last Year
    DECLARE @V_LY_WEEK_DATE  DATE;       --Wtd End Date Last Year
    DECLARE @V_LY_WFD        DATE;       --Start Date Of This Week Last Year
    DECLARE @V_LY_MFD        DATE;       --Start Date Of This Month Last Year
    DECLARE @V_LY_LM_MFD     DATE;       --Start Date Of Last Month Last Year
    DECLARE @V_LY_L2M_MFD    DATE;       --Start Date Of 2 Month Before Last Year
    DECLARE @V_LY_L3M_MFD    DATE;       --Start Date Of 3 Month Before Last Year
    DECLARE @V_LY_L4M_MFD    DATE;       --Start Date Of 4 Month Before Last Year
    DECLARE @V_LY_QFD        DATE;       --Start Date Of This Quarter Last Year
    DECLARE @V_LY_YFD        DATE;       --Start Date Of Last Year
    DECLARE @V_PRIOR_QTD_DATE DATE;      --PRIOR QTD END DATE
    DECLARE @V_PRIOR_QFD      DATE;      --Start Date Of Fiscal PRIOR QTD  
    DECLARE @V_LWMFD          DATE;
    DECLARE @V_LWQFD          DATE;
    DECLARE @V_LWYFD          DATE;
    DECLARE @V_LY_LWMFD       DATE;
    DECLARE @V_LY_LWQFD       DATE;
    DECLARE @V_LY_LWYFD       DATE;
    DECLARE @V_LY_YEAR    		VARCHAR(4);
    DECLARE @V_WK53_FLAG    	CHAR(1);

BEGIN
	SET @PROJECT_NAME = 'KAP';
		
    --Begin log
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_DATE_SAP','DW','START';
    EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_DATE_SAP','','MESSAGE','Begin','','';
        
    BEGIN TRY
      
        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_DATE_SAP','','MESSAGE','Merge','D_DATE','';
        
				MERGE INTO DW.D_DATE T
				USING LD.LD_ZFISDAY_SAP S
				ON ( T.DAY_DATE = S.FISCAL_DAY )
				WHEN MATCHED THEN
				  UPDATE SET T.FISCAL_DATE = S.FISCAL_DAY,
				             T.FISCAL_YEAR = S.FISCAL_YEAR,
				             T.FISCAL_HALFY = S.FISCAL_HALFY,
				             T.FISCAL_QUARTER = S.FISCAL_QUARTER,
				             T.FISCAL_MONTH = S.FISCAL_MONTH,
				             T.FISCAL_MONTH2 = S.FISCAL_MONTH2,
				             T.FISCAL_WEEK_NUMBERS = S.FISCAL_WEEK_NUMBERS,
				             T.FISCAL_WEEK2 = S.FISCAL_WEEK2,
				             T.FISCAL_WEEK_CODE = S.FISCAL_WEEKDAY,
				             T.FISCAL_MONTH_NAME = S.FISCAL_MONTH_NAME
				WHEN NOT MATCHED THEN
				  INSERT ( DAY_DATE,
				           FISCAL_DATE,
				           FISCAL_YEAR,
				           FISCAL_HALFY,
				           FISCAL_QUARTER,
				           FISCAL_MONTH,
				           FISCAL_MONTH2,
				           FISCAL_WEEK_NUMBERS,
				           FISCAL_WEEK2,
				           FISCAL_WEEK_CODE,
				           FISCAL_MONTH_NAME)
				  VALUES (S.FISCAL_DAY,
				          S.FISCAL_DAY,
				          S.FISCAL_YEAR,
				          S.FISCAL_HALFY,
				          S.FISCAL_QUARTER,
				          S.FISCAL_MONTH,
				          S.FISCAL_MONTH2,
				          S.FISCAL_WEEK_NUMBERS,
				          S.FISCAL_WEEK2,
				          S.FISCAL_WEEKDAY,
				          S.FISCAL_MONTH_NAME); 
 
	  		SET @V_CUR_DATE = DATEADD (DD,-1,CAST(DATEADD(HH,8,GETUTCDATE()) AS DATE));	--T-1
	  		
    		SET @v_msg = 'Update W/M/Q/YTD on ' + FORMAT(@V_CUR_DATE,'yyyyMMdd');
    		
    		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_DATE_SAP','','MESSAGE','Note',@v_msg,'';
    		
        --Begin log
        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_DATE_SAP','','MESSAGE','Update','Normal Calendar','';
        
        --Set Variables
        SET @V_WFD           = DATEADD(DD,1-(DATEPART(WEEKDAY,@V_CUR_DATE)+@@DATEFIRST-1)%7,@V_CUR_DATE);
        SET @V_MFD           = DATEADD(MM,DATEDIFF(MM,0,@V_CUR_DATE),0);
        SET @V_LM_MFD        = DATEADD(MM,-1,@V_MFD);
        SET @V_L2M_MFD       = DATEADD(MM,-2,@V_MFD);
        SET @V_L3M_MFD       = DATEADD(MM,-3,@V_MFD);
        SET @V_L4M_MFD       = DATEADD(MM,-4,@V_MFD);
        SET @V_QFD           = DATEADD(QQ,DATEDIFF(QQ,0,@V_CUR_DATE),0)
        SET @V_YFD           = DATEADD(YY,DATEDIFF(YY,0,@V_CUR_DATE),0);
        SET @V_LY_CUR_DATE   = DATEADD(YY,-1,@V_CUR_DATE);
        SET @V_LY_WEEK_DATE  = DATEADD(DD,-364,@V_CUR_DATE);
        SET @V_LY_WFD        = DATEADD(WW,DATEDIFF(WW,0,DATEADD(DD,-1,@V_LY_WEEK_DATE)),0);
        SET @V_LY_MFD        = DATEADD(MM,DATEDIFF(MM,0,@V_LY_CUR_DATE),0);
        SET @V_LY_LM_MFD     = DATEADD(MM,-1,@V_LY_MFD);
        SET @V_LY_L2M_MFD    = DATEADD(MM,-2,@V_LY_MFD);
        SET @V_LY_L3M_MFD    = DATEADD(MM,-3,@V_LY_MFD);
        SET @V_LY_L4M_MFD    = DATEADD(MM,-4,@V_LY_MFD);
        SET @V_LY_QFD        = DATEADD(QQ,DATEDIFF(QQ,0,@V_LY_CUR_DATE),0)
        SET @V_LY_YFD        = DATEADD(YY,DATEDIFF(YY,0,@V_LY_CUR_DATE),0);
        SET @V_PRIOR_QTD_DATE = DATEADD(DD,DATEDIFF(DD,@V_QFD,@V_CUR_DATE),DATEADD( QQ,-1,@V_QFD));
        
        --UPDATE Normal Calendar
        UPDATE DW.D_DATE
        SET DAILY = CASE DAY_DATE
                      WHEN DATEADD(DAY,1,@V_CUR_DATE) THEN 'Today'
                      WHEN @V_CUR_DATE THEN 'Yesterday'
                      WHEN DATEADD(DAY,-1,@V_CUR_DATE) THEN 'Yesterday-1'
                      WHEN DATEADD(DAY,1,@V_LY_CUR_DATE) THEN 'LY Today'
                      WHEN @V_LY_CUR_DATE THEN 'LY Yesterday'
                      WHEN DATEADD(DAY,-1,@V_LY_CUR_DATE) THEN 'LY Yesterday-1'
                      ELSE 'NA'
                    END ,
              WTD = CASE WHEN DAY_DATE BETWEEN @V_WFD AND @V_CUR_DATE THEN 'WTD'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-7,@V_WFD) AND DATEADD( DAY,-1,@V_WFD) THEN 'Week-1'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-14,@V_WFD) AND DATEADD( DAY,-8,@V_WFD) THEN 'Week-2'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-21,@V_WFD) AND DATEADD( DAY,-15,@V_WFD) THEN 'Week-3'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-28,@V_WFD) AND DATEADD( DAY,-22,@V_WFD) THEN 'Week-4'
                         WHEN DAY_DATE BETWEEN @V_LY_WFD AND @V_LY_WEEK_DATE THEN 'LY WTD'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-7,@V_LY_WFD) AND DATEADD( DAY,-1,@V_LY_WFD) THEN 'LY Week-1'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-14,@V_LY_WFD) AND DATEADD( DAY,-8,@V_LY_WFD) THEN 'LY Week-2'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-21,@V_LY_WFD) AND DATEADD( DAY,-15,@V_LY_WFD) THEN 'LY Week-3'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-28,@V_LY_WFD) AND DATEADD( DAY,-22,@V_LY_WFD) THEN 'LY Week-4'
                      ELSE 'NA'
                    END ,
              MTD = CASE WHEN DAY_DATE BETWEEN @V_MFD AND @V_CUR_DATE THEN 'MTD'
                         WHEN DAY_DATE BETWEEN @V_LM_MFD AND DATEADD( DAY,-1,@V_WFD) THEN 'Month-1'
                         WHEN DAY_DATE BETWEEN @V_L2M_MFD AND DATEADD( DAY,-1,@V_LM_MFD) THEN 'Month-2'
                         WHEN DAY_DATE BETWEEN @V_L3M_MFD AND DATEADD( DAY,-1,@V_L2M_MFD) THEN 'Month-3'
                         WHEN DAY_DATE BETWEEN @V_L4M_MFD AND DATEADD( DAY,-1,@V_L3M_MFD) THEN 'Month-4'
                         WHEN DAY_DATE BETWEEN @V_LY_MFD AND @V_LY_CUR_DATE THEN 'LY MTD'
                         WHEN DAY_DATE BETWEEN @V_LY_LM_MFD AND DATEADD( DAY,-1,@V_LY_MFD) THEN 'LY Month-1'
                         WHEN DAY_DATE BETWEEN @V_LY_L2M_MFD AND DATEADD( DAY,-1,@V_LY_LM_MFD) THEN 'LY Month-2'
                         WHEN DAY_DATE BETWEEN @V_LY_L3M_MFD AND DATEADD( DAY,-1,@V_LY_L2M_MFD) THEN 'LY Month-3'
                         WHEN DAY_DATE BETWEEN @V_LY_L4M_MFD AND DATEADD( DAY,-1,@V_LY_L3M_MFD) THEN 'LY Month-4'
                      ELSE 'NA'
                    END ,
              QTD =  CASE
                         WHEN DAY_DATE BETWEEN @V_QFD AND @V_CUR_DATE THEN 'QTD'
                         WHEN DAY_DATE BETWEEN @V_LY_QFD AND @V_LY_CUR_DATE THEN 'LY QTD'
                         ELSE 'NA'
                     END,
              YTD =  CASE
                         WHEN DAY_DATE BETWEEN @V_YFD AND @V_CUR_DATE THEN 'YTD'
                         WHEN DAY_DATE BETWEEN @V_LY_YFD AND @V_LY_CUR_DATE THEN 'LY YTD'
                         ELSE 'NA'
                     END,
              PRIOR_WTD = CASE 
                              WHEN DAY_DATE BETWEEN DATEADD( DAY,-7,@V_WFD) AND DATEADD( DAY,-7,@V_CUR_DATE) THEN 'Prior WTD'
                              ELSE 'NA'
                          END,
              PRIOR_MTD = CASE 
                              WHEN DAY_DATE BETWEEN DATEADD( MM,-1,@V_MFD) AND DATEADD( MM,-1,@V_CUR_DATE) THEN 'Prior MTD'
                              ELSE 'NA'
                          END,
              PRIOR_QTD = CASE 
                              WHEN DAY_DATE BETWEEN DATEADD( QQ,-1,@V_QFD) AND DATEADD(QQ,-1,@V_CUR_DATE) THEN 'Prior QTD'
                              ELSE 'NA'
                          END
                
        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_DATE_SAP','','MESSAGE','Update','Fiscal Calendar','';       
        
        --Set Variables: When wk53 vs wk52, LYWTD is blank, LYMTD is whole month
        SET @V_WK53_FLAG = (SELECT CASE WHEN RIGHT(FISCAL_WEEK2,2) > '52' THEN 'Y' ELSE 'N' END FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
             
        SELECT  @V_WFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_WEEK2 IN (SELECT FISCAL_WEEK2 FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT  @V_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT FISCAL_MONTH2 FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT  @V_LWMFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT FISCAL_MONTH2 FROM DW.D_DATE WHERE DAY_DATE = DATEADD(DD,-7,@V_CUR_DATE));

        SELECT @V_LM_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(MM,-1,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_L2M_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(MM,-2,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_L3M_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(MM,-3,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_L4M_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(MM,-4,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_QFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR = (SELECT FISCAL_YEAR FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE)
        AND FISCAL_QUARTER = (SELECT FISCAL_QUARTER FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);

        SELECT  @V_LWQFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR = (SELECT FISCAL_YEAR FROM DW.D_DATE WHERE DAY_DATE = DATEADD(DD,-7,@V_CUR_DATE))
        AND FISCAL_QUARTER = (SELECT FISCAL_QUARTER FROM DW.D_DATE WHERE DAY_DATE = DATEADD(DD,-7,@V_CUR_DATE));

        SELECT @V_PRIOR_QFD  = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR = (SELECT DATEPART(YY,DATEADD(QQ,-1,CAST(FISCAL_MONTH2+'01' AS DATE))) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE)
        AND FISCAL_QUARTER = (SELECT DATEPART(QQ,DATEADD(QQ,-1,CAST(FISCAL_MONTH2+'01' AS DATE))) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
         
        SELECT  @V_YFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR IN (SELECT FISCAL_YEAR FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);

        SELECT  @V_LWYFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR IN (SELECT FISCAL_YEAR FROM DW.D_DATE WHERE DAY_DATE = DATEADD(DD,-7,@V_CUR_DATE));
        
        SET @V_LY_YEAR = (SELECT CONVERT(VARCHAR(4),DATEADD(YY,-1,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_LY_WFD = MIN(FISCAL_DATE)
				FROM DW.D_DATE
				WHERE FISCAL_WEEK2 = (SELECT CASE WHEN @V_WK53_FLAG = 'Y' THEN FISCAL_YEAR + '01' ELSE @V_LY_YEAR + RIGHT(FISCAL_WEEK2,2) END FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_LY_MFD = MIN(FISCAL_DATE)
				FROM DW.D_DATE
				WHERE FISCAL_MONTH2 = (SELECT @V_LY_YEAR + RIGHT(FISCAL_MONTH2,2) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_LY_LM_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(MM,-13,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_LY_L2M_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(MM,-14,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_LY_L3M_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(MM,-15,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_LY_L4M_MFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(MM,-16,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);

        SELECT @V_LY_QFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR = @V_LY_YEAR
        AND FISCAL_QUARTER = (SELECT FISCAL_QUARTER FROM DW.D_DATE WHERE DAY_DATE = @V_CUR_DATE);
        
        SELECT @V_LY_YFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR = @V_LY_YEAR;

        SELECT @V_LY_CUR_DATE = CASE WHEN @V_WK53_FLAG = 'Y' THEN MAX(DAY_DATE) ELSE DATEADD(DAY,DATEDIFF(DAY,@V_WFD,@V_CUR_DATE),@V_LY_WFD) END
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR = @V_LY_YEAR
        GROUP BY FISCAL_YEAR;
	   		
	   		SELECT @V_LY_LWMFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_MONTH2 IN (SELECT CONVERT(VARCHAR(6),DATEADD(YY,-1,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = DATEADD(DD,-7,@V_CUR_DATE));
        
				SELECT @V_LY_LWQFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR = (SELECT CONVERT(VARCHAR(4),DATEADD(YY,-1,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = DATEADD(DD,-7,@V_CUR_DATE))
        AND FISCAL_QUARTER = (SELECT FISCAL_QUARTER FROM DW.D_DATE WHERE DAY_DATE = DATEADD(DD,-7,@V_CUR_DATE));
        
        SELECT @V_LY_LWYFD = MIN(DAY_DATE)
        FROM DW.D_DATE 
        WHERE FISCAL_YEAR = (SELECT CONVERT(VARCHAR(4),DATEADD(YY,-1,CAST(FISCAL_MONTH2+'01' AS DATE)),112) FROM DW.D_DATE WHERE DAY_DATE = DATEADD(DD,-7,@V_CUR_DATE));

        UPDATE DW.D_DATE
        SET FISCAL_DAILY = CASE DAY_DATE
                             WHEN DATEADD(DAY,1,@V_CUR_DATE) THEN 'Today'
                             WHEN @V_CUR_DATE THEN 'Yesterday'
                             WHEN DATEADD(DAY,-1,@V_CUR_DATE) THEN 'Yesterday-1'
                             WHEN DATEADD(DAY,1,@V_LY_CUR_DATE) THEN 'FS LY Today'
                             WHEN @V_LY_CUR_DATE THEN 'FS LY Yesterday'
                             WHEN DATEADD(DAY,-1,@V_LY_CUR_DATE) THEN 'FS LY Yesterday-1'
                             ELSE 'NA'
                           END ,
       FISCAL_WTD = CASE WHEN DAY_DATE BETWEEN @V_WFD AND @V_CUR_DATE THEN 'FS WTD'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-7,@V_WFD) AND DATEADD( DAY,-1,@V_WFD) THEN 'FS Week-1'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-14,@V_WFD) AND DATEADD( DAY,-8,@V_WFD) THEN 'FS Week-2'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-21,@V_WFD) AND DATEADD( DAY,-15,@V_WFD) THEN 'FS Week-3'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-28,@V_WFD) AND DATEADD( DAY,-22,@V_WFD) THEN 'FS Week-4'
                         WHEN DAY_DATE BETWEEN @V_LY_WFD AND @V_LY_CUR_DATE AND @V_WK53_FLAG = 'N' THEN 'FS LY WTD'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-7,@V_LY_WFD) AND DATEADD( DAY,-1,@V_LY_WFD) THEN 'FS LY Week-1'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-14,@V_LY_WFD) AND DATEADD( DAY,-8,@V_LY_WFD) THEN 'FS LY Week-2'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-21,@V_LY_WFD) AND DATEADD( DAY,-15,@V_LY_WFD) THEN 'FS LY Week-3'
                         WHEN DAY_DATE BETWEEN DATEADD( DAY,-28,@V_LY_WFD) AND DATEADD( DAY,-22,@V_LY_WFD) THEN 'FS LY Week-4'
                      ELSE 'NA'
                    END ,
       FISCAL_MTD = CASE WHEN DAY_DATE BETWEEN @V_MFD AND @V_CUR_DATE THEN 'FS MTD'
                         WHEN DAY_DATE BETWEEN @V_LM_MFD AND DATEADD( DAY,-1,@V_MFD) THEN 'FS Month-1'
                         WHEN DAY_DATE BETWEEN @V_L2M_MFD AND DATEADD( DAY,-1,@V_LM_MFD) THEN 'FS Month-2'
                         WHEN DAY_DATE BETWEEN @V_L3M_MFD AND DATEADD( DAY,-1,@V_L2M_MFD) THEN 'FS Month-3'
                         WHEN DAY_DATE BETWEEN @V_L4M_MFD AND DATEADD( DAY,-1,@V_L3M_MFD) THEN 'FS Month-4'
                         WHEN DAY_DATE BETWEEN @V_LY_MFD AND @V_LY_CUR_DATE THEN 'FS LY MTD'
                         WHEN DAY_DATE BETWEEN @V_LY_LM_MFD AND DATEADD( DAY,-1,@V_LY_MFD) THEN 'FS LY Month-1'
                         WHEN DAY_DATE BETWEEN @V_LY_L2M_MFD AND DATEADD( DAY,-1,@V_LY_LM_MFD) THEN 'FS LY Month-2'
                         WHEN DAY_DATE BETWEEN @V_LY_L3M_MFD AND DATEADD( DAY,-1,@V_LY_L2M_MFD) THEN 'FS LY Month-3'
                         WHEN DAY_DATE BETWEEN @V_LY_L4M_MFD AND DATEADD( DAY,-1,@V_LY_L3M_MFD) THEN 'FS LY Month-4'
                      ELSE 'NA'
                    END ,
       FISCAL_QTD =  CASE
                         WHEN DAY_DATE BETWEEN @V_QFD AND @V_CUR_DATE THEN 'FS QTD'
                         WHEN DAY_DATE BETWEEN @V_LY_QFD AND @V_LY_CUR_DATE THEN 'FS LY QTD'
                         ELSE 'NA'
                     END,
       FISCAL_YTD =  CASE
                         WHEN DAY_DATE BETWEEN @V_YFD AND @V_CUR_DATE THEN 'FS YTD'
                         WHEN DAY_DATE BETWEEN @V_LY_YFD AND @V_LY_CUR_DATE THEN 'FS LY YTD'
                         ELSE 'NA'
                     END,
       FISCAL_PRIOR_WTD =  CASE
                                WHEN DAY_DATE BETWEEN DATEADD( DAY,-7,@V_WFD) AND DATEADD(DAY,-7,@V_CUR_DATE) THEN 'FS Prior WTD'
                                ELSE 'NA'
                           END,
       FISCAL_PRIOR_MTD =  CASE
                                WHEN DAY_DATE BETWEEN @V_LM_MFD AND DATEADD(DD,CASE WHEN DATEDIFF(DD,@V_MFD,@V_CUR_DATE) > 27 THEN 27 ELSE DATEDIFF(DD,@V_MFD,@V_CUR_DATE) END,@V_LM_MFD) THEN 'FS PRIOR MTD'
                                ELSE 'NA'
                           END,
       FISCAL_PRIOR_QTD =  CASE
                                WHEN DAY_DATE BETWEEN @V_PRIOR_QFD AND DATEADD(DD,CASE WHEN DATEDIFF(DD,@V_QFD,@V_CUR_DATE) > 90 THEN 90 ELSE DATEDIFF(DD,@V_QFD,@V_CUR_DATE) END,@V_PRIOR_QFD) THEN 'FS PRIOR QTD'
                                ELSE 'NA'
                           END,
       ---------------TO LAST WEEK 
       FISCAL_MTD_WK_1 =  CASE
                                WHEN DAY_DATE BETWEEN @V_LWMFD AND DATEADD( DAY,-1,@V_WFD) THEN 'FS MTD @ Wk-1'
                                WHEN DAY_DATE BETWEEN @V_LY_LWMFD AND DATEADD( DAY,-1,@V_LY_WFD) THEN 'FS LY MTD @ Wk-1'
                                ELSE 'NA'
                           END,
       FISCAL_QTD_WK_1 =  CASE
                                WHEN DAY_DATE BETWEEN @V_LWQFD AND DATEADD( DAY,-1,@V_WFD) THEN 'FS QTD @ Wk-1'
                                WHEN DAY_DATE BETWEEN @V_LY_LWQFD AND DATEADD( DAY,-1,@V_LY_WFD) THEN 'FS LY QTD @ Wk-1'
                                ELSE 'NA'
                           END,
       FISCAL_YTD_WK_1 =  CASE
                                WHEN DAY_DATE BETWEEN @V_LWYFD AND DATEADD( DAY,-1,@V_WFD) THEN 'FS YTD @ Wk-1'
                                WHEN DAY_DATE BETWEEN @V_LY_LWYFD AND DATEADD( DAY,-1,@V_LY_WFD) THEN 'FS LY YTD @ Wk-1'
                                ELSE 'NA'
                           END
                           
	  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_DATE_SAP','','MESSAGE','End','','';
  
    END TRY

    BEGIN CATCH

        SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
                @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_DATE_SAP','','EXCEPTION','',@errorcode,@errormsg;

    END CATCH
    
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_DATE_SAP','DW','END';
END

GO

/****** Object:  StoredProcedure [DW].[SP_D_EXCHANGE_RATE_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_EXCHANGE_RATE_SAP] 
AS
	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50);
	DECLARE @FISCAL_CY NVARCHAR(10),@CNT INT 
  DECLARE @FISCAL_LY NVARCHAR(10)
 	DECLARE @D_DATE_TMP  TABLE (
	   FISCAL_YEAR             NVARCHAR(10),
	   FISCAL_MONTH2           NVARCHAR(10),
	   CY_DATE                 DATE,
	   LY_DATE                 DATE
    )
    	
  BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_EXCHANGE_RATE_SAP','DM','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_EXCHANGE_RATE_SAP', '', 'DW', 'Begin', '', '';
		         		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_EXCHANGE_RATE_SAP','','DW','Merge','D_EXCHANGE_RATE_SAP','';
			
		MERGE INTO DW.D_EXCHANGE_RATE_SAP A
		USING (SELECT T.*,
		              LEAD(DATEADD(DAY,-1,EFFECTIVE_DATE), 1, '9999-12-31')
		                OVER(
		                  PARTITION BY EX_RATE_TYPE, FROM_CURRENCY, TO_CURRENCY
		                  ORDER BY EFFECTIVE_DATE) EFFECTIVE_END_DATE
		         FROM (SELECT [MANDT]                                          AS CLIENT,
		                      [KURST]                                          AS EX_RATE_TYPE,
		                      [FCURR]                                          AS FROM_CURRENCY,
		                      [TCURR]                                          AS TO_CURRENCY,
		                      CAST(CONVERT(VARCHAR, 99999999 - GDATU) AS DATE) AS EFFECTIVE_DATE,
		                      [UKURS]                                          AS EX_RATE_SAP,
		                      CASE WHEN [UKURS] < 0 THEN ROUND(1/ABS([UKURS]),5) ELSE [UKURS] END AS EX_RATE,
		                      [FFACT],
		                      [TFACT]
		                 FROM [STG].[STG_TCURR_ExchangeRate_SAP]) T
		         WHERE (T.EX_RATE_TYPE = 'M' AND T.EFFECTIVE_DATE >= '2020-7-24')
		         	 	OR T.EX_RATE_TYPE <> 'M') B
		ON ( A.EX_RATE_TYPE = B.EX_RATE_TYPE
		     AND A.FROM_CURRENCY = B.FROM_CURRENCY
		     AND A.TO_CURRENCY = B.TO_CURRENCY
		     AND A.EFFECTIVE_DATE = B.EFFECTIVE_DATE )
		WHEN MATCHED THEN
		  UPDATE SET A.CLIENT = B.CLIENT,
		  A.EX_RATE_SAP = B.EX_RATE_SAP,
		             A.EX_RATE = B.EX_RATE,
		             A.FFACT = B.FFACT,
		             A.TFACT = B.TFACT,
		             A.EFFECTIVE_END_DATE = B.EFFECTIVE_END_DATE
		WHEN NOT MATCHED THEN
		  INSERT ( CLIENT,
		           EX_RATE_TYPE,
		           FROM_CURRENCY,
		           TO_CURRENCY,
		           EFFECTIVE_DATE,
		           EX_RATE_SAP,
		           EX_RATE,
		           FFACT,
		           TFACT,
		           EFFECTIVE_END_DATE)
		  VALUES ( B.CLIENT,
		           B.EX_RATE_TYPE,
		           B.FROM_CURRENCY,
		           B.TO_CURRENCY,
		           B.EFFECTIVE_DATE,
		           B.EX_RATE_SAP,
		           B.EX_RATE,
		           B.FFACT,
		           B.TFACT,
		           B.EFFECTIVE_END_DATE); 


		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_EXCHANGE_RATE_SAP','','DW','Merge','D_EXCHANGE_RATE_CHANGE_POS','';
		
		
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_EXCHANGE_RATE_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_EXCHANGE_RATE_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_EXCHANGE_RATE_SAP','DM','END';
END

GO
/****** Object:  StoredProcedure [DW].[SP_D_FSHSEASONSMAT_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [DW].[SP_D_FSHSEASONSMAT_SAP]
AS

	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_FSHSEASONSMAT_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_FSHSEASONSMAT_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_FSHSEASONSMAT_SAP','','DW','Merge','','';

		MERGE INTO DW.D_FSHSEASONSMAT_SAP A
		USING (SELECT [MANDT],
		              [MATNR],
		              [FSH_SGT],
		              [FSH_SEASON_YEAR],
		              [FSH_SEASON],
		              [FSH_COLLECTION],
		              [FSH_THEME],
		              [SEASON1],
		              [SEASON2],
		              [SEASON3],
		              [DESTEXT],
		              [SEA_INDICATOR],
		              [SATNR],
		              [RFM_KEYITEM]
		         FROM STG.STG_FSHSEASONSMAT_Material_SAP) B
		ON ( A.MANDT = B.MANDT
		     AND A.MATNR = B.MATNR
		     AND A.FSH_SGT = B.FSH_SGT
		     AND A.FSH_SEASON_YEAR = B.FSH_SEASON_YEAR
		     AND A.FSH_SEASON = B.FSH_SEASON
		     AND A.FSH_COLLECTION = B.FSH_COLLECTION
		     AND A.FSH_THEME = B.FSH_THEME )
		WHEN MATCHED THEN
		  UPDATE SET A.[SEASON1] = B.[SEASON1],
		             A.[SEASON2] = B.[SEASON2],
		             A.[SEASON3] = B.[SEASON3],
		             A.[DESTEXT] = B.[DESTEXT],
		             A.[SEA_INDICATOR] = B.[SEA_INDICATOR],
		             A.[SATNR] = B.[SATNR],
		             A.[RFM_KEYITEM] = B.[RFM_KEYITEM]
		WHEN NOT MATCHED THEN
		  INSERT( [MANDT],
		          [MATNR],
		          [FSH_SGT],
		          [FSH_SEASON_YEAR],
		          [FSH_SEASON],
		          [FSH_COLLECTION],
		          [FSH_THEME],
		          [SEASON1],
		          [SEASON2],
		          [SEASON3],
		          [DESTEXT],
		          [SEA_INDICATOR],
		          [SATNR],
		          [RFM_KEYITEM] )
		  VALUES( B.[MANDT],
		          B.[MATNR],
		          B.[FSH_SGT],
		          B.[FSH_SEASON_YEAR],
		          B.[FSH_SEASON],
		          B.[FSH_COLLECTION],
		          B.[FSH_THEME],
		          B.[SEASON1],
		          B.[SEASON2],
		          B.[SEASON3],
		          B.[DESTEXT],
		          B.[SEA_INDICATOR],
		          B.[SATNR],
		          B.[RFM_KEYITEM] ); 

 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_FSHSEASONSMAT_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_FSHSEASONSMAT_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_FSHSEASONSMAT_SAP','DW','END';
END
	     
GO
/****** Object:  StoredProcedure [DW].[SP_D_KLAH_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_KLAH_SAP]
AS

	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_KLAH_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_KLAH_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_KLAH_SAP','','DW','Merge','','';

		MERGE INTO DW.D_KLAH_SAP A
		USING STG.STG_KLAH_Class_SAP B
		ON A.CLINT = B.CLINT
		WHEN MATCHED THEN
		  UPDATE SET A.MANDT = B.MANDT,
		  A.[KLART] = B.[KLART],
		             A.[CLASS] = B.[CLASS],
		             A.[STATU] = B.[STATU],
		             A.[KLAGR] = B.[KLAGR],
		             A.[BGRSE] = B.[BGRSE],
		             A.[BGRKL] = B.[BGRKL],
		             A.[BGRKP] = B.[BGRKP],
		             A.[ANAME] = B.[ANAME],
		             A.[ADATU] = B.[ADATU],
		             A.[VNAME] = B.[VNAME],
		             A.[VDATU] = B.[VDATU],
		             A.[VONDT] = B.[VONDT],
		             A.[BISDT] = B.[BISDT],
		             A.[ANZUO] = B.[ANZUO],
		             A.[PRAUS] = B.[PRAUS],
		             A.[SICHT] = B.[SICHT],
		             A.[DOKNR] = B.[DOKNR],
		             A.[DOKAR] = B.[DOKAR],
		             A.[DOKTL] = B.[DOKTL],
		             A.[DOKVR] = B.[DOKVR],
		             A.[DINKZ] = B.[DINKZ],
		             A.[NNORM] = B.[NNORM],
		             A.[NORMN] = B.[NORMN],
		             A.[NORMB] = B.[NORMB],
		             A.[NRMT1] = B.[NRMT1],
		             A.[NRMT2] = B.[NRMT2],
		             A.[AUSGD] = B.[AUSGD],
		             A.[VERSD] = B.[VERSD],
		             A.[VERSI] = B.[VERSI],
		             A.[LEIST] = B.[LEIST],
		             A.[VERWE] = B.[VERWE],
		             A.[SPART] = B.[SPART],
		             A.[LREF3] = B.[LREF3],
		             A.[WWSKZ] = B.[WWSKZ],
		             A.[WWSSI] = B.[WWSSI],
		             A.[POTPR] = B.[POTPR],
		             A.[CLOBK] = B.[CLOBK],
		             A.[CLMUL] = B.[CLMUL],
		             A.[CVIEW] = B.[CVIEW],
		             A.[DISST] = B.[DISST],
		             A.[MEINS] = B.[MEINS],
		             A.[CLMOD] = B.[CLMOD],
		             A.[VWSTL] = B.[VWSTL],
		             A.[VWPLA] = B.[VWPLA],
		             A.[CLALT] = B.[CLALT],
		             A.[LBREI] = B.[LBREI],
		             A.[BNAME] = B.[BNAME],
		             A.[MAXBL] = B.[MAXBL],
		             A.[KNOBJ] = B.[KNOBJ],
		             A.[LOCLA] = B.[LOCLA],
		             A.[KATALOG] = B.[KATALOG],
		             A.[KDOKAZ] = B.[KDOKAZ],
		             A.[GENRKZ] = B.[GENRKZ],
		             A.[LASTCHANGEDDATETIME] = B.[LASTCHANGEDDATETIME]
		WHEN NOT MATCHED THEN
		  INSERT( MANDT,
							CLINT,
							KLART,
							CLASS,
							STATU,
							KLAGR,
							BGRSE,
							BGRKL,
							BGRKP,
							ANAME,
							ADATU,
							VNAME,
							VDATU,
							VONDT,
							BISDT,
							ANZUO,
							PRAUS,
							SICHT,
							DOKNR,
							DOKAR,
							DOKTL,
							DOKVR,
							DINKZ,
							NNORM,
							NORMN,
							NORMB,
							NRMT1,
							NRMT2,
							AUSGD,
							VERSD,
							VERSI,
							LEIST,
							VERWE,
							SPART,
							LREF3,
							WWSKZ,
							WWSSI,
							POTPR,
							CLOBK,
							CLMUL,
							CVIEW,
							DISST,
							MEINS,
							CLMOD,
							VWSTL,
							VWPLA,
							CLALT,
							LBREI,
							BNAME,
							MAXBL,
							KNOBJ,
							LOCLA,
							KATALOG,
							KDOKAZ,
							GENRKZ,
							LASTCHANGEDDATETIME )
		  VALUES( B.MANDT,
							B.CLINT,
							B.KLART,
							B.CLASS,
							B.STATU,
							B.KLAGR,
							B.BGRSE,
							B.BGRKL,
							B.BGRKP,
							B.ANAME,
							B.ADATU,
							B.VNAME,
							B.VDATU,
							B.VONDT,
							B.BISDT,
							B.ANZUO,
							B.PRAUS,
							B.SICHT,
							B.DOKNR,
							B.DOKAR,
							B.DOKTL,
							B.DOKVR,
							B.DINKZ,
							B.NNORM,
							B.NORMN,
							B.NORMB,
							B.NRMT1,
							B.NRMT2,
							B.AUSGD,
							B.VERSD,
							B.VERSI,
							B.LEIST,
							B.VERWE,
							B.SPART,
							B.LREF3,
							B.WWSKZ,
							B.WWSSI,
							B.POTPR,
							B.CLOBK,
							B.CLMUL,
							B.CVIEW,
							B.DISST,
							B.MEINS,
							B.CLMOD,
							B.VWSTL,
							B.VWPLA,
							B.CLALT,
							B.LBREI,
							B.BNAME,
							B.MAXBL,
							B.KNOBJ,
							B.LOCLA,
							B.KATALOG,
							B.KDOKAZ,
							B.GENRKZ,
							B.LASTCHANGEDDATETIME ); 

   
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_KLAH_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_KLAH_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_KLAH_SAP','DW','END';
END
	  
GO

/****** Object:  StoredProcedure [DW].[SP_D_PRODUCT_COST_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_PRODUCT_COST_SAP] 
  --Load Stand cost(Group) from KEKO & KEPH
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create

AS
	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
 		
  BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_PRODUCT_COST_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_PRODUCT_COST_SAP', '', 'DW', 'Begin', '', '';		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_PRODUCT_COST_SAP','','DW','Merge','D_PRODUCT_COST_SAP','';
		
		MERGE INTO DW.D_PRODUCT_COST_SAP A
				USING (SELECT T.*
				FROM (
				SELECT K.KALKA                                                 AS COST_TYPE,
							        STUFF(K.WERKS, 1, PATINDEX ('%[^0]%', K.WERKS) - 1, '') AS STORE_CODE,
							        K.MATNR                                                 AS MATERIAL_CODE,
							        CASE K.KADAT
							          WHEN '00000000' THEN NULL
							          ELSE CAST(K.KADAT AS DATE)
							        END                                                     AS EFFECTIVE_FROM_DATE,
							        CASE K.BIDAT
							          WHEN '00000000' THEN NULL
							          ELSE CAST(K.BIDAT AS DATE)
							        END                                                     AS EFFECTIVE_TO_DATE,
							        P.KST001+P.KST002+P.KST003+P.KST004+P.KST005+P.KST006+P.KST007+P.KST008+P.KST009+P.KST010
							        +P.KST011+P.KST012+P.KST013+P.KST014+P.KST015+P.KST016+P.KST017+P.KST018	AS STDCOST_AMT,
									ROW_NUMBER() OVER(PARTITION BY K.KALKA,STUFF(K.WERKS, 1, PATINDEX ('%[^0]%', K.WERKS) - 1, ''),K.MATNR,CASE K.KADAT
							          WHEN '00000000' THEN NULL
							          ELSE CAST(K.KADAT AS DATE)
							        END ORDER BY K.TVERS DESC) AS ROW_NUM
							   FROM [STG].[STG_KEKO_ProductCosting_SAP] K,
							        [STG].[STG_KEPH_ProductCosting_SAP] P
							  WHERE P.KALNR = K.KALNR
							        AND P.KALKA = K.KALKA
							        --AND P.PATNR = K.PATNR
							        AND P.KADKY = K.KADKY
							        AND P.TVERS = K.TVERS
							        AND P.BWVAR = K.BWVAR
							        AND K.KALKA = 'GR'
							        AND P.LOSFX <> 'X'
									) T
							WHERE T.ROW_NUM=1		
									) B
				ON ( A.COST_TYPE = B.COST_TYPE
							AND A.STORE_CODE = B.STORE_CODE
							AND A.MATERIAL_CODE = B.MATERIAL_CODE
							AND A.EFFECTIVE_FROM_DATE = B.EFFECTIVE_FROM_DATE 
							)
				WHEN MATCHED THEN
				  UPDATE SET A.EFFECTIVE_TO_DATE = B.EFFECTIVE_TO_DATE,
				  					 A.STDCOST_AMT = B.STDCOST_AMT
				WHEN NOT MATCHED THEN
				  INSERT ( COST_TYPE,
		             	 STORE_CODE,
		             	 MATERIAL_CODE,
		             	 EFFECTIVE_FROM_DATE,
		             	 EFFECTIVE_TO_DATE,
		             	 STDCOST_AMT)
				  VALUES (B.COST_TYPE,
									B.STORE_CODE,
									B.MATERIAL_CODE,
									B.EFFECTIVE_FROM_DATE,
									B.EFFECTIVE_TO_DATE,
									B.STDCOST_AMT);
									
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_PRODUCT_COST_SAP','','DW','Update','Effective Period','';
		
		MERGE INTO DW.D_PRODUCT_COST_SAP A
				USING (SELECT *
							 FROM (SELECT T1.COST_TYPE,
					  	        T1.STORE_CODE,
					  	        T1.MATERIAL_CODE,
					  	        T1.EFFECTIVE_FROM_DATE,
					  	        T1.EFFECTIVE_TO_DATE,
					  	        CASE WHEN T1.RID = 1 THEN '2020-7-26' ELSE T1.EFFECTIVE_FROM_DATE END AS EFFECTIVE_FROM_DATE_NEW,	--Extend begin date
					  	        ISNULL(DATEADD(DAY,-1,LEAD(T1.EFFECTIVE_FROM_DATE,1) OVER(PARTITION BY T1.COST_TYPE,T1.STORE_CODE,T1.MATERIAL_CODE ORDER BY T1.EFFECTIVE_FROM_DATE)),'9999-12-31') AS EFFECTIVE_TO_DATE_NEW
					  		FROM (SELECT COST_TYPE,
					  					       STORE_CODE,
					  					       MATERIAL_CODE,
					  					       EFFECTIVE_FROM_DATE,
					  					       EFFECTIVE_TO_DATE,
					  					       STDCOST_AMT,
					  					       ROW_NUMBER() OVER(PARTITION BY COST_TYPE,STORE_CODE,MATERIAL_CODE ORDER BY EFFECTIVE_FROM_DATE) RID
					  					  FROM DW.D_PRODUCT_COST_SAP) T1) T2
					  		WHERE T2.EFFECTIVE_FROM_DATE <> T2.EFFECTIVE_FROM_DATE_NEW
					  			 OR T2.EFFECTIVE_TO_DATE <> T2.EFFECTIVE_TO_DATE_NEW) B
				ON ( A.COST_TYPE = B.COST_TYPE
							AND A.STORE_CODE = B.STORE_CODE
							AND A.MATERIAL_CODE = B.MATERIAL_CODE
							AND A.EFFECTIVE_FROM_DATE = B.EFFECTIVE_FROM_DATE )
				WHEN MATCHED THEN
				  UPDATE SET A.EFFECTIVE_FROM_DATE = B.EFFECTIVE_FROM_DATE_NEW,
				  					 A.EFFECTIVE_TO_DATE = B.EFFECTIVE_TO_DATE_NEW;
		
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_PRODUCT_COST_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_PRODUCT_COST_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_PRODUCT_COST_SAP','DW','END';
END

GO
/****** Object:  StoredProcedure [DW].[SP_D_SKU_STDCOST_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_SKU_STDCOST_SAP]
  --Load data from loading to warehouse
  --Creadted by   : Daniel
  --Version       : 1.0
  --Modify History: Create
AS

DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @PROJECT_NAME varchar(50)
    DECLARE @FILE_ID INT

BEGIN
	
	SET @PROJECT_NAME = 'KAP';
	
  EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_SKU_STDCOST_SAP','DW','START';   
  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_SKU_STDCOST_SAP','','MESSAGE','Begin','',''; 
  BEGIN TRY
            BEGIN TRAN LOAD_D_SKU_STDCOST_SAP
 
            MERGE INTO DW.D_SKU_STDCOST_SAP T1
            USING LD.LD_SKU_STDCOST_SAP T2
            ON (T1.STORE_CODE     = T2.STORE_CODE
            AND T1.MATERIAL_CODE  = T2.MATERIAL_CODE)
            WHEN MATCHED THEN 
            UPDATE SET LOCAL_CURRENCY = T2.LOCAL_CURRENCY,
                      FISCAL_PERIOD    = T2.FISCAL_PERIOD,
                      PRICE_UNIT       = T2.PRICE_UNIT,
                      STDCOST_AMT      = T2.STDCOST_AMT
            WHEN NOT MATCHED THEN
            INSERT (  LOCAL_CURRENCY,
                      STORE_CODE,
                      FISCAL_PERIOD,
                      PRICE_UNIT,
                      STDCOST_AMT,
                      MATERIAL_CODE
                   )
            VALUES (  T2.LOCAL_CURRENCY,
                      T2.STORE_CODE,
                      T2.FISCAL_PERIOD,
                      T2.PRICE_UNIT,
                      T2.STDCOST_AMT,
                      T2.MATERIAL_CODE
                    );
       
        COMMIT TRAN LOAD_D_SKU_STDCOST_SAP
        
        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_SKU_STDCOST_SAP','','MESSAGE','End','','';
    END TRY

    BEGIN CATCH
        ROLLBACK

        SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
               @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

        SET @v_msg='FILE_ID:'+CAST(@FILE_ID AS VARCHAR(20));
        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_SKU_STDCOST_SAP','','EXCEPTION',@v_msg,@errorcode,@errormsg;
     END CATCH
     
     EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_SKU_STDCOST_SAP','DW','END';
     
 END



GO
/****** Object:  StoredProcedure [DW].[SP_D_STORE_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [DW].[SP_D_STORE_SAP]
  --Load data from loading to warehouse
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create
AS

    DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @PROJECT_NAME varchar(50)
    DECLARE @FILE_ID INT
  
BEGIN
	SET @PROJECT_NAME = 'KAP';

    BEGIN TRY
 
        --Begin log
        EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_STORE_SAP','DM','START';
        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_STORE_SAP', '', 'MESSAGE', 'Begin', '', '';
        
        --Update loading table data
				MERGE INTO DW.D_STORE_SAP T
				USING (SELECT B1.*,
				              B2.SYSTEM_CODE,
				              ISNULL(B3.REMARK_B, B2.KEYDATA_DESC) KEYDATA_DESC
				         FROM LD.LD_STORE_SAP B1
				              LEFT JOIN DW.D_KEYDATA_MASTER_POS B2
				                     ON B1.COUNTRY = B2.KEYDATA_CODE
				                        AND B2.CODE_TYPE = 'COUNTRY_CURRENCY'
				              LEFT JOIN DW.D_KEYDATA_SAP B3
				                     ON B1.SALES_ORGANIZATION = B3.SAP_CODE
				                        AND B3.CODE_TYPE = 'SALES_ORG') S
				ON ( T.STORE_CODE = S.STORE_CODE )
				WHEN MATCHED THEN
				  UPDATE SET T.COUNTRY = S.COUNTRY,
				             T.SALES_ORGANIZATION = S.SALES_ORGANIZATION,
				             T.SALES_DISTRICT = S.SALES_DISTRICT,
				             T.CITY = S.CITY,
				             T.SITE_ENGLISH_NAME = S.SITE_ENGLISH_NAME,
				             T.SITE_CHINESE_NAME = S.SITE_CHINESE_NAME,
				             T.STORE_OPEN_DATE = S.STORE_OPEN_DATE,
				             T.CLOSE_DATE_OF_STORE = S.CLOSE_DATE_OF_STORE,
				             T.LOCAL_CURRENCY = S.KEYDATA_DESC,
				             T.STORE_AREA = S.STORE_AREA,
				             T.STORE_TYPE_CODE = S.STORE_TYPE_CODE,
				             T.REGION_CODE = S.REGION_CODE,
				             T.STORE_TYPE_DESC = S.STORE_TYPE_DESC,
				             T.REGION_DESC = S.REGION_DESC,
				             T.OLD_STORE_CODE = S.OLD_STORE_CODE,
				             T.AE_CODE = S.AE_CODE,
				             T.SUB_CHANNEL = S.SUB_CHANNEL,
				             T.COMPANY_CODE = S.COMPANY_CODE,
				             T.PURCHASE_ORG = S.PURCHASE_ORG,
				             T.COUNTRY_NAME = S.SYSTEM_CODE,
				             T.NEW_CO_FLAG = S.NEW_CO_FLAG,
				             T.COMPANY_DESC = S.COMPANY_DESC,
				             T.DISTRIBUTION_CHANNEL = S.DISTRIBUTION_CHANNEL,
				             T.STORE_CATEGORY = S.STORE_CATEGORY,
				             T.STORE_CATEGORY_DESC = S.STORE_CATEGORY_DESC,
				             T.CUSTOMER_NUMBER = S.CUSTOMER_NUMBER
				WHEN NOT MATCHED THEN
				  INSERT ( STORE_CODE,
				           COUNTRY,
				           SALES_ORGANIZATION,
				           SALES_DISTRICT,
				           CITY,
				           SITE_ENGLISH_NAME,
				           SITE_CHINESE_NAME,
				           STORE_OPEN_DATE,
				           CLOSE_DATE_OF_STORE,
				           LOCAL_CURRENCY,
				           STORE_AREA,
				           STORE_TYPE_CODE,
				           REGION_CODE,
				           STORE_TYPE_DESC,
				           REGION_DESC,
				           OLD_STORE_CODE,
				           AE_CODE,
				           SUB_CHANNEL,
				           COMPANY_CODE,
				           PURCHASE_ORG,
				           COUNTRY_NAME,
				           NEW_CO_FLAG,
				           COMPANY_DESC,
				           DISTRIBUTION_CHANNEL,
				           STORE_CATEGORY,
				           STORE_CATEGORY_DESC,
				           CUSTOMER_NUMBER)
				  VALUES (S.STORE_CODE,
				          S.COUNTRY,
				          S.SALES_ORGANIZATION,
				          S.SALES_DISTRICT,
				          S.CITY,
				          S.SITE_ENGLISH_NAME,
				          S.SITE_CHINESE_NAME,
				          S.STORE_OPEN_DATE,
				          S.CLOSE_DATE_OF_STORE,
				          S.KEYDATA_DESC,--LOCAL_CURRENCY
				          S.STORE_AREA,
				          S.STORE_TYPE_CODE,
				          S.REGION_CODE,
				          S.STORE_TYPE_DESC,
				          S.REGION_DESC,
				          S.OLD_STORE_CODE,
				          S.AE_CODE,
				          S.SUB_CHANNEL,
				          S.COMPANY_CODE,
				          S.PURCHASE_ORG,
				          S.SYSTEM_CODE,
				          S.NEW_CO_FLAG,
				          S.COMPANY_DESC,
				          S.DISTRIBUTION_CHANNEL,
				          S.STORE_CATEGORY,
				          S.STORE_CATEGORY_DESC,
				          S.CUSTOMER_NUMBER);      
/*			  
			  UPDATE DW.D_STORE_SAP
			  SET BRAND_ID = ISNULL(B.BRAND_ID,0),BRAND_CODE = ISNULL(B.BRAND,'NA')
			  FROM DW.D_STORE_SAP A
			  LEFT JOIN DW.D_STORE_SDB B
			  ON A.STORE_CODE = B.STORE_CODE;
*/			  
			  --Add by Bingo.You on 20190725: Add Company Desc
				UPDATE T
				   SET COMPANY_DESC = K.KEYDATA_DESC
				  FROM DW.D_STORE_SAP T
				       INNER JOIN DW.D_KEYDATA_MASTER_POS K
				               ON K.CODE_TYPE = 'VFA_COMPANY'
				                  AND T.COMPANY_CODE = K.KEYDATA_CODE
				 WHERE T.COMPANY_DESC IS NULL OR T.COMPANY_DESC = '';			  
        
        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_STORE_SAP', '', 'MESSAGE', 'End', '', '';
        
        END TRY

            BEGIN CATCH
        

                SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
                       @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

                SET @v_msg='FILE_ID:'+CAST(@FILE_ID AS VARCHAR(20));

                EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_STORE_SAP','','EXCEPTION',@v_msg,@errorcode,@errormsg;
                
            END CATCH
            
            EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_STORE_SAP','DM','END';
    END


GO
/****** Object:  StoredProcedure [DW].[SP_D_SWOR_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_SWOR_SAP]
AS

	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_SWOR_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_SWOR_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_SWOR_SAP','','DW','Merge','','';

		MERGE INTO DW.D_SWOR_SAP A
		USING STG.STG_SWOR_Class_SAP B
		ON A.[CLINT] = B.[CLINT]
		   AND A.[SPRAS] = B.[SPRAS]
		   AND A.[KLPOS] = B.[KLPOS]
		WHEN MATCHED THEN
		  UPDATE SET A.[MANDT] = B.[MANDT],
		  A.[KSCHL] = B.[KSCHL],
		             A.[KSCHG] = B.[KSCHG]
		WHEN NOT MATCHED THEN
		  INSERT( [MANDT],
		          [CLINT],
		          [SPRAS],
		          [KLPOS],
		          [KSCHL],
		          [KSCHG] )
		  VALUES( B.[MANDT],
		          B.[CLINT],
		          B.[SPRAS],
		          B.[KLPOS],
		          B.[KSCHL],
		          B.[KSCHG] ); 
	   
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_SWOR_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_SWOR_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_SWOR_SAP','DW','END';
END 
GO
/****** Object:  StoredProcedure [DW].[SP_D_T001_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [DW].[SP_D_T001_SAP]
AS

	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50);
	
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_T001_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_T001_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_T001_SAP','','DW','Merge','','';

		MERGE INTO DW.D_T001_SAP A
		USING (SELECT STUFF(BUKRS, 1, PATINDEX ('%[^0]%', BUKRS) - 1, '') AS BUKRS_2,
		              T.*
		         FROM STG.STG_T001_Company_SAP T) B
		ON A.[MANDT] = B.[MANDT]
		   AND A.[BUKRS] = B.BUKRS_2
		WHEN MATCHED THEN
		  UPDATE SET A.[BUTXT] = B.[BUTXT],
		             A.[ORT01] = B.[ORT01],
		             A.[LAND1] = B.[LAND1],
		             A.[WAERS] = B.[WAERS],
		             A.[SPRAS] = B.[SPRAS],
		             A.[KTOPL] = B.[KTOPL],
		             A.[WAABW] = B.[WAABW],
		             A.[PERIV] = B.[PERIV],
		             A.[KOKFI] = B.[KOKFI],
		             A.[RCOMP] = B.[RCOMP],
		             A.[ADRNR] = B.[ADRNR],
		             A.[STCEG] = B.[STCEG],
		             A.[FIKRS] = B.[FIKRS],
		             A.[XFMCO] = B.[XFMCO],
		             A.[XFMCB] = B.[XFMCB],
		             A.[XFMCA] = B.[XFMCA],
		             A.[TXJCD] = B.[TXJCD],
		             A.[FMHRDATE] = B.[FMHRDATE],
		             A.[XTEMPLT] = B.[XTEMPLT],
		             A.[BUVAR] = B.[BUVAR],
		             A.[FDBUK] = B.[FDBUK],
		             A.[XFDIS] = B.[XFDIS],
		             A.[XVALV] = B.[XVALV],
		             A.[XSKFN] = B.[XSKFN],
		             A.[KKBER] = B.[KKBER],
		             A.[XMWSN] = B.[XMWSN],
		             A.[MREGL] = B.[MREGL],
		             A.[XGSBE] = B.[XGSBE],
		             A.[XGJRV] = B.[XGJRV],
		             A.[XKDFT] = B.[XKDFT],
		             A.[XPROD] = B.[XPROD],
		             A.[XEINK] = B.[XEINK],
		             A.[XJVAA] = B.[XJVAA],
		             A.[XVVWA] = B.[XVVWA],
		             A.[XSLTA] = B.[XSLTA],
		             A.[XFDMM] = B.[XFDMM],
		             A.[XFDSD] = B.[XFDSD],
		             A.[XEXTB] = B.[XEXTB],
		             A.[EBUKR] = B.[EBUKR],
		             A.[KTOP2] = B.[KTOP2],
		             A.[UMKRS] = B.[UMKRS],
		             A.[BUKRS_GLOB] = B.[BUKRS_GLOB],
		             A.[FSTVA] = B.[FSTVA],
		             A.[OPVAR] = B.[OPVAR],
		             A.[XCOVR] = B.[XCOVR],
		             A.[TXKRS] = B.[TXKRS],
		             A.[WFVAR] = B.[WFVAR],
		             A.[XBBBF] = B.[XBBBF],
		             A.[XBBBE] = B.[XBBBE],
		             A.[XBBBA] = B.[XBBBA],
		             A.[XBBKO] = B.[XBBKO],
		             A.[XSTDT] = B.[XSTDT],
		             A.[MWSKV] = B.[MWSKV],
		             A.[MWSKA] = B.[MWSKA],
		             A.[IMPDA] = B.[IMPDA],
		             A.[XNEGP] = B.[XNEGP],
		             A.[XKKBI] = B.[XKKBI],
		             A.[WT_NEWWT] = B.[WT_NEWWT],
		             A.[PP_PDATE] = B.[PP_PDATE],
		             A.[INFMT] = B.[INFMT],
		             A.[FSTVARE] = B.[FSTVARE],
		             A.[KOPIM] = B.[KOPIM],
		             A.[DKWEG] = B.[DKWEG],
		             A.[OFFSACCT] = B.[OFFSACCT],
		             A.[BAPOVAR] = B.[BAPOVAR],
		             A.[XCOS] = B.[XCOS],
		             A.[XCESSION] = B.[XCESSION],
		             A.[XSPLT] = B.[XSPLT],
		             A.[SURCCM] = B.[SURCCM],
		             A.[DTPROV] = B.[DTPROV],
		             A.[DTAMTC] = B.[DTAMTC],
		             A.[DTTAXC] = B.[DTTAXC],
		             A.[DTTDSP] = B.[DTTDSP],
		             A.[DTAXR] = B.[DTAXR],
		             A.[XVATDATE] = B.[XVATDATE],
		             A.[PST_PER_VAR] = B.[PST_PER_VAR],
		             A.[XBBSC] = B.[XBBSC],
		             A.[F_OBSOLETE] = B.[F_OBSOLETE],
		             A.[FM_DERIVE_ACC] = B.[FM_DERIVE_ACC]
		WHEN NOT MATCHED THEN
		  INSERT( [MANDT],
		          [BUKRS],
		          [BUTXT],
		          [ORT01],
		          [LAND1],
		          [WAERS],
		          [SPRAS],
		          [KTOPL],
		          [WAABW],
		          [PERIV],
		          [KOKFI],
		          [RCOMP],
		          [ADRNR],
		          [STCEG],
		          [FIKRS],
		          [XFMCO],
		          [XFMCB],
		          [XFMCA],
		          [TXJCD],
		          [FMHRDATE],
		          [XTEMPLT],
		          [BUVAR],
		          [FDBUK],
		          [XFDIS],
		          [XVALV],
		          [XSKFN],
		          [KKBER],
		          [XMWSN],
		          [MREGL],
		          [XGSBE],
		          [XGJRV],
		          [XKDFT],
		          [XPROD],
		          [XEINK],
		          [XJVAA],
		          [XVVWA],
		          [XSLTA],
		          [XFDMM],
		          [XFDSD],
		          [XEXTB],
		          [EBUKR],
		          [KTOP2],
		          [UMKRS],
		          [BUKRS_GLOB],
		          [FSTVA],
		          [OPVAR],
		          [XCOVR],
		          [TXKRS],
		          [WFVAR],
		          [XBBBF],
		          [XBBBE],
		          [XBBBA],
		          [XBBKO],
		          [XSTDT],
		          [MWSKV],
		          [MWSKA],
		          [IMPDA],
		          [XNEGP],
		          [XKKBI],
		          [WT_NEWWT],
		          [PP_PDATE],
		          [INFMT],
		          [FSTVARE],
		          [KOPIM],
		          [DKWEG],
		          [OFFSACCT],
		          [BAPOVAR],
		          [XCOS],
		          [XCESSION],
		          [XSPLT],
		          [SURCCM],
		          [DTPROV],
		          [DTAMTC],
		          [DTTAXC],
		          [DTTDSP],
		          [DTAXR],
		          [XVATDATE],
		          [PST_PER_VAR],
		          [XBBSC],
		          [F_OBSOLETE],
		          [FM_DERIVE_ACC] )
		  VALUES( B.[MANDT],
		          B.BUKRS_2,
		          B.[BUTXT],
		          B.[ORT01],
		          B.[LAND1],
		          B.[WAERS],
		          B.[SPRAS],
		          B.[KTOPL],
		          B.[WAABW],
		          B.[PERIV],
		          B.[KOKFI],
		          B.[RCOMP],
		          B.[ADRNR],
		          B.[STCEG],
		          B.[FIKRS],
		          B.[XFMCO],
		          B.[XFMCB],
		          B.[XFMCA],
		          B.[TXJCD],
		          B.[FMHRDATE],
		          B.[XTEMPLT],
		          B.[BUVAR],
		          B.[FDBUK],
		          B.[XFDIS],
		          B.[XVALV],
		          B.[XSKFN],
		          B.[KKBER],
		          B.[XMWSN],
		          B.[MREGL],
		          B.[XGSBE],
		          B.[XGJRV],
		          B.[XKDFT],
		          B.[XPROD],
		          B.[XEINK],
		          B.[XJVAA],
		          B.[XVVWA],
		          B.[XSLTA],
		          B.[XFDMM],
		          B.[XFDSD],
		          B.[XEXTB],
		          B.[EBUKR],
		          B.[KTOP2],
		          B.[UMKRS],
		          B.[BUKRS_GLOB],
		          B.[FSTVA],
		          B.[OPVAR],
		          B.[XCOVR],
		          B.[TXKRS],
		          B.[WFVAR],
		          B.[XBBBF],
		          B.[XBBBE],
		          B.[XBBBA],
		          B.[XBBKO],
		          B.[XSTDT],
		          B.[MWSKV],
		          B.[MWSKA],
		          B.[IMPDA],
		          B.[XNEGP],
		          B.[XKKBI],
		          B.[WT_NEWWT],
		          B.[PP_PDATE],
		          B.[INFMT],
		          B.[FSTVARE],
		          B.[KOPIM],
		          B.[DKWEG],
		          B.[OFFSACCT],
		          B.[BAPOVAR],
		          B.[XCOS],
		          B.[XCESSION],
		          B.[XSPLT],
		          B.[SURCCM],
		          B.[DTPROV],
		          B.[DTAMTC],
		          B.[DTTAXC],
		          B.[DTTDSP],
		          B.[DTAXR],
		          B.[XVATDATE],
		          B.[PST_PER_VAR],
		          B.[XBBSC],
		          B.[F_OBSOLETE],
		          B.[FM_DERIVE_ACC] ); 
  
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_T001_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_T001_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_T001_SAP','DW','END';
END 
GO
/****** Object:  StoredProcedure [DW].[SP_D_T001K_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_T001K_SAP]
AS

	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50);
	
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_T001K_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_T001K_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_T001K_SAP','','DW','Merge','','';

		MERGE INTO DW.D_T001K_SAP A
		USING (SELECT [MANDT],
		              STUFF(BWKEY, 1, PATINDEX ('%[^0]%', BWKEY) - 1, '') AS [BWKEY],
		              STUFF(BUKRS, 1, PATINDEX ('%[^0]%', BUKRS) - 1, '') AS [BUKRS],
		              [BWMOD],
		              [XBKNG],
		              [MLBWA],
		              [MLBWV],
		              [XVKBW],
		              [ERKLAERKOM],
		              [UPROF],
		              [WBPRO],
		              [MLAST],
		              [MLASV],
		              [BDIFP],
		              [XLBPD],
		              [XEWRX],
		              [X2FDO],
		              [PRSFR],
		              [MLCCS],
		              [XEFRE],
		              [EFREJ],
		              [/FMP/PRSFR],
		              [/FMP/PRFRGR]
		         FROM STG.STG_T001K_Valuation_SAP) B
		ON A.[BWKEY] = B.[BWKEY]
		WHEN MATCHED THEN
		  UPDATE SET A.[MANDT] = B.[MANDT],
		  					 A.[BUKRS] = B.[BUKRS],
		             A.[BWMOD] = B.[BWMOD],
		             A.[XBKNG] = B.[XBKNG],
		             A.[MLBWA] = B.[MLBWA],
		             A.[MLBWV] = B.[MLBWV],
		             A.[XVKBW] = B.[XVKBW],
		             A.[ERKLAERKOM] = B.[ERKLAERKOM],
		             A.[UPROF] = B.[UPROF],
		             A.[WBPRO] = B.[WBPRO],
		             A.[MLAST] = B.[MLAST],
		             A.[MLASV] = B.[MLASV],
		             A.[BDIFP] = B.[BDIFP],
		             A.[XLBPD] = B.[XLBPD],
		             A.[XEWRX] = B.[XEWRX],
		             A.[X2FDO] = B.[X2FDO],
		             A.[PRSFR] = B.[PRSFR],
		             A.[MLCCS] = B.[MLCCS],
		             A.[XEFRE] = B.[XEFRE],
		             A.[EFREJ] = B.[EFREJ],
		             A.[/FMP/PRSFR] = B.[/FMP/PRSFR],
		             A.[/FMP/PRFRGR] = B.[/FMP/PRFRGR]
		WHEN NOT MATCHED THEN
		  INSERT( [MANDT],
		          [BWKEY],
		          [BUKRS],
		          [BWMOD],
		          [XBKNG],
		          [MLBWA],
		          [MLBWV],
		          [XVKBW],
		          [ERKLAERKOM],
		          [UPROF],
		          [WBPRO],
		          [MLAST],
		          [MLASV],
		          [BDIFP],
		          [XLBPD],
		          [XEWRX],
		          [X2FDO],
		          [PRSFR],
		          [MLCCS],
		          [XEFRE],
		          [EFREJ],
		          [/FMP/PRSFR],
		          [/FMP/PRFRGR] )
		  VALUES( B.[MANDT],
		          B.[BWKEY],
		          B.[BUKRS],
		          B.[BWMOD],
		          B.[XBKNG],
		          B.[MLBWA],
		          B.[MLBWV],
		          B.[XVKBW],
		          B.[ERKLAERKOM],
		          B.[UPROF],
		          B.[WBPRO],
		          B.[MLAST],
		          B.[MLASV],
		          B.[BDIFP],
		          B.[XLBPD],
		          B.[XEWRX],
		          B.[X2FDO],
		          B.[PRSFR],
		          B.[MLCCS],
		          B.[XEFRE],
		          B.[EFREJ],
		          B.[/FMP/PRSFR],
		          B.[/FMP/PRFRGR] ); 
	   
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_T001K_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_T001K_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_T001K_SAP','DW','END';
END 
GO
/****** Object:  StoredProcedure [DW].[SP_D_WRF1_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_WRF1_SAP]
AS

	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50);
	
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_WRF1_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_WRF1_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_WRF1_SAP','','DW','Merge','D_WRF1_SAP','';

		MERGE INTO DW.D_WRF1_SAP A
		USING (SELECT STUFF(T.LOCNR, 1, PATINDEX ('%[^0]%', T.LOCNR) - 1, '') AS LOCNR_2,
		              T.*
		         FROM STG.STG_WRF1_SAP T) B
		ON A.LOCNR = B.LOCNR_2
		WHEN MATCHED THEN
		  UPDATE SET A.[MANDT] = B.[MANDT],
		  					 A.EROED = B.EROED,
		             A.SCHLD = B.SCHLD,
		             A.SPDAB = B.SPDAB,
		             A.SPDBI = B.SPDBI,
		             A.AUTOB = B.AUTOB,
		             A.KOPRO = B.KOPRO,
		             A.LAYVR = B.LAYVR,
		             A.FLVAR = B.FLVAR,
		             A.STFAK = B.STFAK,
		             A.WANID = B.WANID,
		             A.MOAB1 = B.MOAB1,
		             A.MOBI1 = B.MOBI1,
		             A.MOAB2 = B.MOAB2,
		             A.MOBI2 = B.MOBI2,
		             A.DIAB1 = B.DIAB1,
		             A.DIBI1 = B.DIBI1,
		             A.DIAB2 = B.DIAB2,
		             A.DIBI2 = B.DIBI2,
		             A.MIAB1 = B.MIAB1,
		             A.MIBI1 = B.MIBI1,
		             A.MIAB2 = B.MIAB2,
		             A.MIBI2 = B.MIBI2,
		             A.DOAB1 = B.DOAB1,
		             A.DOBI1 = B.DOBI1,
		             A.DOAB2 = B.DOAB2,
		             A.DOBI2 = B.DOBI2,
		             A.FRAB1 = B.FRAB1,
		             A.FRBI1 = B.FRBI1,
		             A.FRAB2 = B.FRAB2,
		             A.FRBI2 = B.FRBI2,
		             A.SAAB1 = B.SAAB1,
		             A.SABI1 = B.SABI1,
		             A.SAAB2 = B.SAAB2,
		             A.SABI2 = B.SABI2,
		             A.SOAB1 = B.SOAB1,
		             A.SOBI1 = B.SOBI1,
		             A.SOAB2 = B.SOAB2,
		             A.SOBI2 = B.SOBI2,
		             A.VERFL = B.VERFL,
		             A.VERFE = B.VERFE,
		             A.SPGR1 = B.SPGR1,
		             A.INPRO = B.INPRO,
		             A.EKOAR = B.EKOAR,
		             A.KZLIK = B.KZLIK,
		             A.BETRP = B.BETRP,
		             A.ERDAT = B.ERDAT,
		             A.ERNAM = B.ERNAM,
		             A.NLMATFB = B.NLMATFB,
		             A.BWWRK = B.BWWRK,
		             A.BWVKO = B.BWVKO,
		             A.BWVTW = B.BWVTW,
		             A.BBPRO = B.BBPRO,
		             A.VKBUR_WRK = B.VKBUR_WRK,
		             A.VLFKZ = B.VLFKZ,
		             A.LSTFL = B.LSTFL,
		             A.LIGRD = B.LIGRD,
		             A.VKORG = B.VKORG,
		             A.VTWEG = B.VTWEG,
		             A.DESROI = B.DESROI,
		             A.TIMINC = B.TIMINC,
		             A.POSWS = B.POSWS,
		             A.SSOPT_PRO = B.SSOPT_PRO,
		             A.WBPRO = B.WBPRO,
		             A.ORGPRICE = B.ORGPRICE,
		             A.PRCTR = B.PRCTR,
		             A.RMA_PROF = B.RMA_PROF,
		             A.RMA_VKORG = B.RMA_VKORG,
		             A.RMA_VTWEG = B.RMA_VTWEG
		WHEN NOT MATCHED THEN
		  INSERT( MANDT,
		          LOCNR,
		          EROED,
		          SCHLD,
		          SPDAB,
		          SPDBI,
		          AUTOB,
		          KOPRO,
		          LAYVR,
		          FLVAR,
		          STFAK,
		          WANID,
		          MOAB1,
		          MOBI1,
		          MOAB2,
		          MOBI2,
		          DIAB1,
		          DIBI1,
		          DIAB2,
		          DIBI2,
		          MIAB1,
		          MIBI1,
		          MIAB2,
		          MIBI2,
		          DOAB1,
		          DOBI1,
		          DOAB2,
		          DOBI2,
		          FRAB1,
		          FRBI1,
		          FRAB2,
		          FRBI2,
		          SAAB1,
		          SABI1,
		          SAAB2,
		          SABI2,
		          SOAB1,
		          SOBI1,
		          SOAB2,
		          SOBI2,
		          VERFL,
		          VERFE,
		          SPGR1,
		          INPRO,
		          EKOAR,
		          KZLIK,
		          BETRP,
		          ERDAT,
		          ERNAM,
		          NLMATFB,
		          BWWRK,
		          BWVKO,
		          BWVTW,
		          BBPRO,
		          VKBUR_WRK,
		          VLFKZ,
		          LSTFL,
		          LIGRD,
		          VKORG,
		          VTWEG,
		          DESROI,
		          TIMINC,
		          POSWS,
		          SSOPT_PRO,
		          WBPRO,
		          ORGPRICE,
		          PRCTR,
		          RMA_PROF,
		          RMA_VKORG,
		          RMA_VTWEG )
		  VALUES( B.MANDT,
		          B.LOCNR_2,
		          B.EROED,
		          B.SCHLD,
		          B.SPDAB,
		          B.SPDBI,
		          B.AUTOB,
		          B.KOPRO,
		          B.LAYVR,
		          B.FLVAR,
		          B.STFAK,
		          B.WANID,
		          B.MOAB1,
		          B.MOBI1,
		          B.MOAB2,
		          B.MOBI2,
		          B.DIAB1,
		          B.DIBI1,
		          B.DIAB2,
		          B.DIBI2,
		          B.MIAB1,
		          B.MIBI1,
		          B.MIAB2,
		          B.MIBI2,
		          B.DOAB1,
		          B.DOBI1,
		          B.DOAB2,
		          B.DOBI2,
		          B.FRAB1,
		          B.FRBI1,
		          B.FRAB2,
		          B.FRBI2,
		          B.SAAB1,
		          B.SABI1,
		          B.SAAB2,
		          B.SABI2,
		          B.SOAB1,
		          B.SOBI1,
		          B.SOAB2,
		          B.SOBI2,
		          B.VERFL,
		          B.VERFE,
		          B.SPGR1,
		          B.INPRO,
		          B.EKOAR,
		          B.KZLIK,
		          B.BETRP,
		          B.ERDAT,
		          B.ERNAM,
		          B.NLMATFB,
		          B.BWWRK,
		          B.BWVKO,
		          B.BWVTW,
		          B.BBPRO,
		          B.VKBUR_WRK,
		          B.VLFKZ,
		          B.LSTFL,
		          B.LIGRD,
		          B.VKORG,
		          B.VTWEG,
		          B.DESROI,
		          B.TIMINC,
		          B.POSWS,
		          B.SSOPT_PRO,
		          B.WBPRO,
		          B.ORGPRICE,
		          B.PRCTR,
		          B.RMA_PROF,
		          B.RMA_VKORG,
		          B.RMA_VTWEG ); 
		
  
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_WRF1_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_WRF1_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_WRF1_SAP','DW','END';
END 
GO
/****** Object:  StoredProcedure [DW].[SP_D_WRFMATGRPSKU_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_D_WRFMATGRPSKU_SAP]
AS

	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_WRFMATGRPSKU_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_WRFMATGRPSKU_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_WRFMATGRPSKU_SAP','','DW','Merge','','';

		SELECT [MANDT],
		       [HIER_ID],
		       T.MATNR,
		       [NODE],
		       CAST(STUFF(T.DATE_FROM, 1, PATINDEX ('%[^0]%', T.DATE_FROM) - 1, '') AS DATE) AS [DATE_FROM],
		       CAST(STUFF(T.DATE_TO, 1, PATINDEX ('%[^0]%', T.DATE_TO) - 1, '') AS DATE)     AS [DATE_TO],
		       [MAINFLG],
		       [STRATEGY]
		INTO #TEMP
		FROM STG.STG_WRFMATGRPSKU_Material_SAP T
		WHERE ISDATE(T.DATE_FROM) = 1
		AND ISDATE(T.DATE_TO) = 1



		MERGE INTO DW.D_WRFMATGRPSKU_SAP A
		USING (SELECT * FROM #TEMP) B
		ON A.[HIER_ID] = B.[HIER_ID]
		   AND A.[MATNR] = B.[MATNR]
		   AND A.[NODE] = B.[NODE]
		   AND A.[DATE_FROM] = B.DATE_FROM
		WHEN MATCHED THEN
		  UPDATE SET A.[MANDT] = B.[MANDT],
		  A.[DATE_TO] = B.DATE_TO,
		             A.[MAINFLG] = B.[MAINFLG],
		             A.[STRATEGY] = B.[STRATEGY]
		WHEN NOT MATCHED THEN
		  INSERT( [MANDT],
		          [HIER_ID],
		          [MATNR],
		          [NODE],
		          [DATE_FROM],
		          [DATE_TO],
		          [MAINFLG],
		          [STRATEGY] )
		  VALUES( B.[MANDT],
		          B.[HIER_ID],
		          B.[MATNR],
		          B.[NODE],
		          B.DATE_FROM,
		          B.DATE_TO,
		          B.[MAINFLG],
		          B.[STRATEGY] ); 

		DROP TABLE #TEMP
   
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_D_WRFMATGRPSKU_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_D_WRFMATGRPSKU_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_D_WRFMATGRPSKU_SAP','DW','END';
END     
GO


/****** Object:  StoredProcedure [DW].[SP_F_EKES_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_F_EKES_SAP]
AS
	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_F_EKES_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_F_EKES_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_EKES_SAP','','DW','Merge','','';

		MERGE INTO DW.F_EKES_SAP A
		USING (SELECT CAST(STUFF(T.EINDT,1,PATINDEX ( '%[^0]%' , T.EINDT )-1 , '') AS DATE) AS EINDT_2,
									CAST(STUFF(T.ERDAT,1,PATINDEX ( '%[^0]%' , T.ERDAT )-1 , '') AS DATE) AS ERDAT_2,
									CAST(STUFF(T.HANDOVERDATE,1,PATINDEX ( '%[^0]%' , T.HANDOVERDATE )-1 , '') AS DATE) AS HANDOVERDATE_2,
									CAST(STUFF(T.[_DATAAGING],1,PATINDEX ( '%[^0]%' , T.[_DATAAGING] )-1 , '') AS DATE) AS [_DATAAGING_2],
									T.* 
						 FROM STG.STG_EKES_VendorConfirmations_SAP T) B
		ON A.[EBELN] = B.[EBELN]
		AND A.[EBELP] = B.[EBELP]
		AND A.[ETENS] = B.[ETENS]
		WHEN MATCHED THEN
		  UPDATE SET A.[MANDT] = B.[MANDT],
								 --A.[EBELN] = B.[EBELN],
								 --A.[EBELP] = B.[EBELP],
								 --A.[ETENS] = B.[ETENS],
								 A.[EBTYP] = B.[EBTYP],
								 A.[EINDT] = B.[EINDT_2],
								 A.[LPEIN] = B.[LPEIN],
								 A.[UZEIT] = B.[UZEIT],
								 A.[ERDAT] = B.[ERDAT_2],
								 A.[EZEIT] = B.[EZEIT],
								 A.[MENGE] = B.[MENGE],
								 A.[DABMG] = B.[DABMG],
								 A.[ESTKZ] = B.[ESTKZ],
								 A.[LOEKZ] = B.[LOEKZ],
								 A.[KZDIS] = B.[KZDIS],
								 A.[XBLNR] = B.[XBLNR],
								 A.[VBELN] = B.[VBELN],
								 A.[VBELP] = B.[VBELP],
								 A.[MPROF] = B.[MPROF],
								 A.[EMATN] = B.[EMATN],
								 A.[MAHNZ] = B.[MAHNZ],
								 A.[CHARG] = B.[CHARG],
								 A.[UECHA] = B.[UECHA],
								 A.[REF_ETENS] = B.[REF_ETENS],
								 A.[IMWRK] = B.[IMWRK],
								 A.[VBELN_ST] = B.[VBELN_ST],
								 A.[VBELP_ST] = B.[VBELP_ST],
								 A.[HANDOVERDATE] = B.[HANDOVERDATE_2],
								 A.[HANDOVERTIME] = B.[HANDOVERTIME],
								 A.[SGT_SCAT] = B.[SGT_SCAT],
								 A.[MSGTSTMP] = B.[MSGTSTMP],
								 A.[/CWM/MENGE] = B.[/CWM/MENGE],
								 A.[/CWM/DABMG] = B.[/CWM/DABMG],
								 A.[_DATAAGING] = B.[_DATAAGING_2],
								 A.[FSH_SALLOC_QTY] = B.[FSH_SALLOC_QTY],
								 A.[ORMNG] = B.[ORMNG],
								 A.[TMS_REF_UUID] = B.[TMS_REF_UUID]
		WHEN NOT MATCHED THEN
		  INSERT( [MANDT],
							[EBELN],
							[EBELP],
							[ETENS],
							[EBTYP],
							[EINDT],
							[LPEIN],
							[UZEIT],
							[ERDAT],
							[EZEIT],
							[MENGE],
							[DABMG],
							[ESTKZ],
							[LOEKZ],
							[KZDIS],
							[XBLNR],
							[VBELN],
							[VBELP],
							[MPROF],
							[EMATN],
							[MAHNZ],
							[CHARG],
							[UECHA],
							[REF_ETENS],
							[IMWRK],
							[VBELN_ST],
							[VBELP_ST],
							[HANDOVERDATE],
							[HANDOVERTIME],
							[SGT_SCAT],
							[MSGTSTMP],
							[/CWM/MENGE],
							[/CWM/DABMG],
							[_DATAAGING],
							[FSH_SALLOC_QTY],
							[ORMNG],
							[TMS_REF_UUID] )
		  VALUES( B.[MANDT],
							B.[EBELN],
							B.[EBELP],
							B.[ETENS],
							B.[EBTYP],
							B.[EINDT_2],
							B.[LPEIN],
							B.[UZEIT],
							B.[ERDAT_2],
							B.[EZEIT],
							B.[MENGE],
							B.[DABMG],
							B.[ESTKZ],
							B.[LOEKZ],
							B.[KZDIS],
							B.[XBLNR],
							B.[VBELN],
							B.[VBELP],
							B.[MPROF],
							B.[EMATN],
							B.[MAHNZ],
							B.[CHARG],
							B.[UECHA],
							B.[REF_ETENS],
							B.[IMWRK],
							B.[VBELN_ST],
							B.[VBELP_ST],
							B.[HANDOVERDATE_2],
							B.[HANDOVERTIME],
							B.[SGT_SCAT],
							B.[MSGTSTMP],
							B.[/CWM/MENGE],
							B.[/CWM/DABMG],
							B.[_DATAAGING_2],
							B.[FSH_SALLOC_QTY],
							B.[ORMNG],
							B.[TMS_REF_UUID] ); 

 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_F_EKES_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_EKES_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_F_EKES_SAP','DW','END';
END
	   
GO
/****** Object:  StoredProcedure [DW].[SP_F_EKKO_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_F_EKKO_SAP]
AS
	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_F_EKKO_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_F_EKKO_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_EKKO_SAP','','DW','Merge','','';

		MERGE INTO DW.F_EKKO_SAP A
		USING (SELECT CAST(STUFF(T.AEDAT,1,PATINDEX ( '%[^0]%' , T.AEDAT )-1 , '') AS DATE) AS AEDAT_2,
									CAST(STUFF(T.BEDAT,1,PATINDEX ( '%[^0]%' , T.BEDAT )-1 , '') AS DATE) AS BEDAT_2,
									CAST(STUFF(T.KDATB,1,PATINDEX ( '%[^0]%' , T.KDATB )-1 , '') AS DATE) AS KDATB_2,
									CAST(STUFF(T.KDATE,1,PATINDEX ( '%[^0]%' , T.KDATE )-1 , '') AS DATE) AS KDATE_2,
									CAST(STUFF(T.BWBDT,1,PATINDEX ( '%[^0]%' , T.BWBDT )-1 , '') AS DATE) AS BWBDT_2,
									CAST(STUFF(T.ANGDT,1,PATINDEX ( '%[^0]%' , T.ANGDT )-1 , '') AS DATE) AS ANGDT_2,
									CAST(STUFF(T.BNDDT,1,PATINDEX ( '%[^0]%' , T.BNDDT )-1 , '') AS DATE) AS BNDDT_2,
									CAST(STUFF(T.GWLDT,1,PATINDEX ( '%[^0]%' , T.GWLDT )-1 , '') AS DATE) AS GWLDT_2,
									CAST(STUFF(T.IHRAN,1,PATINDEX ( '%[^0]%' , T.IHRAN )-1 , '') AS DATE) AS IHRAN_2,
									STUFF(T.LIFNR, 1, PATINDEX ('%[^0]%', T.LIFNR) - 1, '') AS LIFNR_2,
									T.* 
						 FROM STG.STG_EKKO_Purchase_SAP T) B
		ON A.EBELN = B.EBELN
		WHEN MATCHED THEN
		  UPDATE SET A.MANDT = B.MANDT,
		  					 A.BUKRS = B.BUKRS,
		             A.BSTYP = B.BSTYP,
		             A.BSART = B.BSART,
		             A.BSAKZ = B.BSAKZ,
		             A.LOEKZ = B.LOEKZ,
		             A.STATU = B.STATU,
		             A.AEDAT = B.AEDAT_2,
		             A.ERNAM = B.ERNAM,
		             A.LASTCHANGEDATETIME = B.LASTCHANGEDATETIME,
		             A.PINCR = B.PINCR,
		             A.LPONR = B.LPONR,
		             A.LIFNR = B.LIFNR_2,
		             A.SPRAS = B.SPRAS,
		             A.ZTERM = B.ZTERM,
		             A.ZBD1T = B.ZBD1T,
		             A.ZBD2T = B.ZBD2T,
		             A.ZBD3T = B.ZBD3T,
		             A.ZBD1P = B.ZBD1P,
		             A.ZBD2P = B.ZBD2P,
		             A.EKORG = B.EKORG,
		             A.EKGRP = B.EKGRP,
		             A.WAERS = B.WAERS,
		             A.WKURS = B.WKURS,
		             A.KUFIX = B.KUFIX,
		             A.BEDAT = B.BEDAT_2,
		             A.KDATB = B.KDATB_2,
		             A.KDATE = B.KDATE_2,
		             A.BWBDT = B.BWBDT_2,
		             A.ANGDT = B.ANGDT_2,
		             A.BNDDT = B.BNDDT_2,
		             A.GWLDT = B.GWLDT_2,
		             A.AUSNR = B.AUSNR,
		             A.ANGNR = B.ANGNR,
		             A.IHRAN = B.IHRAN_2,
		             A.IHREZ = B.IHREZ,
		             A.VERKF = B.VERKF,
		             A.TELF1 = B.TELF1,
		             A.LLIEF = B.LLIEF,
		             A.KUNNR = B.KUNNR,
		             A.KONNR = B.KONNR,
		             A.ABGRU = B.ABGRU,
		             A.AUTLF = B.AUTLF,
		             A.WEAKT = B.WEAKT,
		             A.RESWK = B.RESWK,
		             A.LBLIF = B.LBLIF,
		             A.INCO1 = B.INCO1,
		             A.INCO2 = B.INCO2,
		             A.KTWRT = B.KTWRT,
		             A.SUBMI = B.SUBMI,
		             A.KNUMV = B.KNUMV,
		             A.KALSM = B.KALSM,
		             A.STAFO = B.STAFO,
		             A.LIFRE = B.LIFRE,
		             A.EXNUM = B.EXNUM,
		             A.UNSEZ = B.UNSEZ,
		             A.LOGSY = B.LOGSY,
		             A.UPINC = B.UPINC,
		             A.STAKO = B.STAKO,
		             A.FRGGR = B.FRGGR,
		             A.FRGSX = B.FRGSX,
		             A.FRGKE = B.FRGKE,
		             A.FRGZU = B.FRGZU,
		             A.FRGRL = B.FRGRL,
		             A.LANDS = B.LANDS,
		             A.LPHIS = B.LPHIS,
		             A.ADRNR = B.ADRNR,
		             A.STCEG_L = B.STCEG_L,
		             A.STCEG = B.STCEG,
		             A.ABSGR = B.ABSGR,
		             A.ADDNR = B.ADDNR,
		             A.KORNR = B.KORNR,
		             A.MEMORY = B.MEMORY,
		             A.PROCSTAT = B.PROCSTAT,
		             A.RLWRT = B.RLWRT,
		             A.REVNO = B.REVNO,
		             A.SCMPROC = B.SCMPROC,
		             A.REASON_CODE = B.REASON_CODE,
		             A.MEMORYTYPE = B.MEMORYTYPE,
		             A.RETTP = B.RETTP,
		             A.RETPC = B.RETPC,
		             A.DPTYP = B.DPTYP,
		             A.DPPCT = B.DPPCT,
		             A.DPAMT = B.DPAMT,
		             A.DPDAT = B.DPDAT,
		             A.MSR_ID = B.MSR_ID,
		             A.HIERARCHY_EXISTS = B.HIERARCHY_EXISTS,
		             A.THRESHOLD_EXISTS = B.THRESHOLD_EXISTS,
		             A.LEGAL_CONTRACT = B.LEGAL_CONTRACT,
		             A.DESCRIPTION = B.DESCRIPTION,
		             A.RELEASE_DATE = B.RELEASE_DATE,
		             A.VSART = B.VSART,
		             A.HANDOVERLOC = B.HANDOVERLOC,
		             A.SHIPCOND = B.SHIPCOND,
		             A.INCOV = B.INCOV,
		             A.INCO2_L = B.INCO2_L,
		             A.INCO3_L = B.INCO3_L,
		             A.GRWCU = B.GRWCU,
		             A.INTRA_REL = B.INTRA_REL,
		             A.INTRA_EXCL = B.INTRA_EXCL,
		             A.QTN_ERLST_SUBMSN_DATE = B.QTN_ERLST_SUBMSN_DATE,
		             A.FOLLOWON_DOC_CAT = B.FOLLOWON_DOC_CAT,
		             A.FOLLOWON_DOC_TYPE = B.FOLLOWON_DOC_TYPE,
		             A.DUMMY_EKKO_INCL_EEW_PS = B.DUMMY_EKKO_INCL_EEW_PS,
		             A.EXTERNALSYSTEM = B.EXTERNALSYSTEM,
		             A.EXTERNALREFERENCEID = B.EXTERNALREFERENCEID,
		             A.EXT_REV_TMSTMP = B.EXT_REV_TMSTMP,
		             A.ISEOPBLOCKED = B.ISEOPBLOCKED,
		             A.ISAGED = B.ISAGED,
		             A.FORCE_ID = B.FORCE_ID,
		             A.FORCE_CNT = B.FORCE_CNT,
		             A.RELOC_ID = B.RELOC_ID,
		             A.RELOC_SEQ_ID = B.RELOC_SEQ_ID,
		             A.SOURCE_LOGSYS = B.SOURCE_LOGSYS,
		             A.FSH_TRANSACTION = B.FSH_TRANSACTION,
		             A.FSH_ITEM_GROUP = B.FSH_ITEM_GROUP,
		             A.FSH_VAS_LAST_ITEM = B.FSH_VAS_LAST_ITEM,
		             A.FSH_OS_STG_CHANGE = B.FSH_OS_STG_CHANGE,
		             A.TMS_REF_UUID = B.TMS_REF_UUID,
		             A.ZAPCGK = B.ZAPCGK,
		             A.APCGK_EXTEND = B.APCGK_EXTEND,
		             A.ZBAS_DATE = B.ZBAS_DATE,
		             A.ZADATTYP = B.ZADATTYP,
		             A.ZSTART_DAT = B.ZSTART_DAT,
		             A.Z_DEV = B.Z_DEV,
		             A.ZINDANX = B.ZINDANX,
		             A.ZLIMIT_DAT = B.ZLIMIT_DAT,
		             A.NUMERATOR = B.NUMERATOR,
		             A.HASHCAL_BDAT = B.HASHCAL_BDAT,
		             A.HASHCAL = B.HASHCAL,
		             A.NEGATIVE = B.NEGATIVE,
		             A.HASHCAL_EXISTS = B.HASHCAL_EXISTS,
		             A.KNOWN_INDEX = B.KNOWN_INDEX,
		             A.POSTAT = B.POSTAT,
		             A.VZSKZ = B.VZSKZ,
		             A.FSH_SNST_STATUS = B.FSH_SNST_STATUS,
		             A.PROCE = B.PROCE,
		             A.CONC = B.CONC,
		             A.CONT = B.CONT,
		             A.COMP = B.COMP,
		             A.OUTR = B.OUTR,
		             A.DESP = B.DESP,
		             A.DESP_DAT = B.DESP_DAT,
		             A.DESP_CARGO = B.DESP_CARGO,
		             A.PARE = B.PARE,
		             A.PARE_DAT = B.PARE_DAT,
		             A.PARE_CARGO = B.PARE_CARGO,
		             A.PFM_CONTRACT = B.PFM_CONTRACT,
		             A.POHF_TYPE = B.POHF_TYPE,
		             A.EQ_EINDT = B.EQ_EINDT,
		             A.EQ_WERKS = B.EQ_WERKS,
		             A.FIXPO = B.FIXPO,
		             A.EKGRP_ALLOW = B.EKGRP_ALLOW,
		             A.WERKS_ALLOW = B.WERKS_ALLOW,
		             A.CONTRACT_ALLOW = B.CONTRACT_ALLOW,
		             A.PSTYP_ALLOW = B.PSTYP_ALLOW,
		             A.FIXPO_ALLOW = B.FIXPO_ALLOW,
		             A.KEY_ID_ALLOW = B.KEY_ID_ALLOW,
		             A.AUREL_ALLOW = B.AUREL_ALLOW,
		             A.DELPER_ALLOW = B.DELPER_ALLOW,
		             A.EINDT_ALLOW = B.EINDT_ALLOW,
		             A.LTSNR_ALLOW = B.LTSNR_ALLOW,
		             A.OTB_LEVEL = B.OTB_LEVEL,
		             A.OTB_COND_TYPE = B.OTB_COND_TYPE,
		             A.KEY_ID = B.KEY_ID,
		             A.OTB_VALUE = B.OTB_VALUE,
		             A.OTB_CURR = B.OTB_CURR,
		             A.OTB_RES_VALUE = B.OTB_RES_VALUE,
		             A.OTB_SPEC_VALUE = B.OTB_SPEC_VALUE,
		             A.SPR_RSN_PROFILE = B.SPR_RSN_PROFILE,
		             A.BUDG_TYPE = B.BUDG_TYPE,
		             A.OTB_STATUS = B.OTB_STATUS,
		             A.OTB_REASON = B.OTB_REASON,
		             A.CHECK_TYPE = B.CHECK_TYPE,
		             A.CON_OTB_REQ = B.CON_OTB_REQ,
		             A.CON_PREBOOK_LEV = B.CON_PREBOOK_LEV,
		             A.CON_DISTR_LEV = B.CON_DISTR_LEV
		WHEN NOT MATCHED THEN
		  INSERT( MANDT,
		          EBELN,
		          BUKRS,
		          BSTYP,
		          BSART,
		          BSAKZ,
		          LOEKZ,
		          STATU,
		          AEDAT,
		          ERNAM,
		          LASTCHANGEDATETIME,
		          PINCR,
		          LPONR,
		          LIFNR,
		          SPRAS,
		          ZTERM,
		          ZBD1T,
		          ZBD2T,
		          ZBD3T,
		          ZBD1P,
		          ZBD2P,
		          EKORG,
		          EKGRP,
		          WAERS,
		          WKURS,
		          KUFIX,
		          BEDAT,
		          KDATB,
		          KDATE,
		          BWBDT,
		          ANGDT,
		          BNDDT,
		          GWLDT,
		          AUSNR,
		          ANGNR,
		          IHRAN,
		          IHREZ,
		          VERKF,
		          TELF1,
		          LLIEF,
		          KUNNR,
		          KONNR,
		          ABGRU,
		          AUTLF,
		          WEAKT,
		          RESWK,
		          LBLIF,
		          INCO1,
		          INCO2,
		          KTWRT,
		          SUBMI,
		          KNUMV,
		          KALSM,
		          STAFO,
		          LIFRE,
		          EXNUM,
		          UNSEZ,
		          LOGSY,
		          UPINC,
		          STAKO,
		          FRGGR,
		          FRGSX,
		          FRGKE,
		          FRGZU,
		          FRGRL,
		          LANDS,
		          LPHIS,
		          ADRNR,
		          STCEG_L,
		          STCEG,
		          ABSGR,
		          ADDNR,
		          KORNR,
		          MEMORY,
		          PROCSTAT,
		          RLWRT,
		          REVNO,
		          SCMPROC,
		          REASON_CODE,
		          MEMORYTYPE,
		          RETTP,
		          RETPC,
		          DPTYP,
		          DPPCT,
		          DPAMT,
		          DPDAT,
		          MSR_ID,
		          HIERARCHY_EXISTS,
		          THRESHOLD_EXISTS,
		          LEGAL_CONTRACT,
		          DESCRIPTION,
		          RELEASE_DATE,
		          VSART,
		          HANDOVERLOC,
		          SHIPCOND,
		          INCOV,
		          INCO2_L,
		          INCO3_L,
		          GRWCU,
		          INTRA_REL,
		          INTRA_EXCL,
		          QTN_ERLST_SUBMSN_DATE,
		          FOLLOWON_DOC_CAT,
		          FOLLOWON_DOC_TYPE,
		          DUMMY_EKKO_INCL_EEW_PS,
		          EXTERNALSYSTEM,
		          EXTERNALREFERENCEID,
		          EXT_REV_TMSTMP,
		          ISEOPBLOCKED,
		          ISAGED,
		          FORCE_ID,
		          FORCE_CNT,
		          RELOC_ID,
		          RELOC_SEQ_ID,
		          SOURCE_LOGSYS,
		          FSH_TRANSACTION,
		          FSH_ITEM_GROUP,
		          FSH_VAS_LAST_ITEM,
		          FSH_OS_STG_CHANGE,
		          TMS_REF_UUID,
		          ZAPCGK,
		          APCGK_EXTEND,
		          ZBAS_DATE,
		          ZADATTYP,
		          ZSTART_DAT,
		          Z_DEV,
		          ZINDANX,
		          ZLIMIT_DAT,
		          NUMERATOR,
		          HASHCAL_BDAT,
		          HASHCAL,
		          NEGATIVE,
		          HASHCAL_EXISTS,
		          KNOWN_INDEX,
		          POSTAT,
		          VZSKZ,
		          FSH_SNST_STATUS,
		          PROCE,
		          CONC,
		          CONT,
		          COMP,
		          OUTR,
		          DESP,
		          DESP_DAT,
		          DESP_CARGO,
		          PARE,
		          PARE_DAT,
		          PARE_CARGO,
		          PFM_CONTRACT,
		          POHF_TYPE,
		          EQ_EINDT,
		          EQ_WERKS,
		          FIXPO,
		          EKGRP_ALLOW,
		          WERKS_ALLOW,
		          CONTRACT_ALLOW,
		          PSTYP_ALLOW,
		          FIXPO_ALLOW,
		          KEY_ID_ALLOW,
		          AUREL_ALLOW,
		          DELPER_ALLOW,
		          EINDT_ALLOW,
		          LTSNR_ALLOW,
		          OTB_LEVEL,
		          OTB_COND_TYPE,
		          KEY_ID,
		          OTB_VALUE,
		          OTB_CURR,
		          OTB_RES_VALUE,
		          OTB_SPEC_VALUE,
		          SPR_RSN_PROFILE,
		          BUDG_TYPE,
		          OTB_STATUS,
		          OTB_REASON,
		          CHECK_TYPE,
		          CON_OTB_REQ,
		          CON_PREBOOK_LEV,
		          CON_DISTR_LEV )
		  VALUES( B.MANDT,
		          B.EBELN,
		          B.BUKRS,
		          B.BSTYP,
		          B.BSART,
		          B.BSAKZ,
		          B.LOEKZ,
		          B.STATU,
		          B.AEDAT_2,
		          B.ERNAM,
		          B.LASTCHANGEDATETIME,
		          B.PINCR,
		          B.LPONR,
		          B.LIFNR_2,
		          B.SPRAS,
		          B.ZTERM,
		          B.ZBD1T,
		          B.ZBD2T,
		          B.ZBD3T,
		          B.ZBD1P,
		          B.ZBD2P,
		          B.EKORG,
		          B.EKGRP,
		          B.WAERS,
		          B.WKURS,
		          B.KUFIX,
		          B.BEDAT_2,
		          B.KDATB_2,
		          B.KDATE_2,
		          B.BWBDT_2,
		          B.ANGDT_2,
		          B.BNDDT_2,
		          B.GWLDT_2,
		          B.AUSNR,
		          B.ANGNR,
		          B.IHRAN_2,
		          B.IHREZ,
		          B.VERKF,
		          B.TELF1,
		          B.LLIEF,
		          B.KUNNR,
		          B.KONNR,
		          B.ABGRU,
		          B.AUTLF,
		          B.WEAKT,
		          B.RESWK,
		          B.LBLIF,
		          B.INCO1,
		          B.INCO2,
		          B.KTWRT,
		          B.SUBMI,
		          B.KNUMV,
		          B.KALSM,
		          B.STAFO,
		          B.LIFRE,
		          B.EXNUM,
		          B.UNSEZ,
		          B.LOGSY,
		          B.UPINC,
		          B.STAKO,
		          B.FRGGR,
		          B.FRGSX,
		          B.FRGKE,
		          B.FRGZU,
		          B.FRGRL,
		          B.LANDS,
		          B.LPHIS,
		          B.ADRNR,
		          B.STCEG_L,
		          B.STCEG,
		          B.ABSGR,
		          B.ADDNR,
		          B.KORNR,
		          B.MEMORY,
		          B.PROCSTAT,
		          B.RLWRT,
		          B.REVNO,
		          B.SCMPROC,
		          B.REASON_CODE,
		          B.MEMORYTYPE,
		          B.RETTP,
		          B.RETPC,
		          B.DPTYP,
		          B.DPPCT,
		          B.DPAMT,
		          B.DPDAT,
		          B.MSR_ID,
		          B.HIERARCHY_EXISTS,
		          B.THRESHOLD_EXISTS,
		          B.LEGAL_CONTRACT,
		          B.DESCRIPTION,
		          B.RELEASE_DATE,
		          B.VSART,
		          B.HANDOVERLOC,
		          B.SHIPCOND,
		          B.INCOV,
		          B.INCO2_L,
		          B.INCO3_L,
		          B.GRWCU,
		          B.INTRA_REL,
		          B.INTRA_EXCL,
		          B.QTN_ERLST_SUBMSN_DATE,
		          B.FOLLOWON_DOC_CAT,
		          B.FOLLOWON_DOC_TYPE,
		          B.DUMMY_EKKO_INCL_EEW_PS,
		          B.EXTERNALSYSTEM,
		          B.EXTERNALREFERENCEID,
		          B.EXT_REV_TMSTMP,
		          B.ISEOPBLOCKED,
		          B.ISAGED,
		          B.FORCE_ID,
		          B.FORCE_CNT,
		          B.RELOC_ID,
		          B.RELOC_SEQ_ID,
		          B.SOURCE_LOGSYS,
		          B.FSH_TRANSACTION,
		          B.FSH_ITEM_GROUP,
		          B.FSH_VAS_LAST_ITEM,
		          B.FSH_OS_STG_CHANGE,
		          B.TMS_REF_UUID,
		          B.ZAPCGK,
		          B.APCGK_EXTEND,
		          B.ZBAS_DATE,
		          B.ZADATTYP,
		          B.ZSTART_DAT,
		          B.Z_DEV,
		          B.ZINDANX,
		          B.ZLIMIT_DAT,
		          B.NUMERATOR,
		          B.HASHCAL_BDAT,
		          B.HASHCAL,
		          B.NEGATIVE,
		          B.HASHCAL_EXISTS,
		          B.KNOWN_INDEX,
		          B.POSTAT,
		          B.VZSKZ,
		          B.FSH_SNST_STATUS,
		          B.PROCE,
		          B.CONC,
		          B.CONT,
		          B.COMP,
		          B.OUTR,
		          B.DESP,
		          B.DESP_DAT,
		          B.DESP_CARGO,
		          B.PARE,
		          B.PARE_DAT,
		          B.PARE_CARGO,
		          B.PFM_CONTRACT,
		          B.POHF_TYPE,
		          B.EQ_EINDT,
		          B.EQ_WERKS,
		          B.FIXPO,
		          B.EKGRP_ALLOW,
		          B.WERKS_ALLOW,
		          B.CONTRACT_ALLOW,
		          B.PSTYP_ALLOW,
		          B.FIXPO_ALLOW,
		          B.KEY_ID_ALLOW,
		          B.AUREL_ALLOW,
		          B.DELPER_ALLOW,
		          B.EINDT_ALLOW,
		          B.LTSNR_ALLOW,
		          B.OTB_LEVEL,
		          B.OTB_COND_TYPE,
		          B.KEY_ID,
		          B.OTB_VALUE,
		          B.OTB_CURR,
		          B.OTB_RES_VALUE,
		          B.OTB_SPEC_VALUE,
		          B.SPR_RSN_PROFILE,
		          B.BUDG_TYPE,
		          B.OTB_STATUS,
		          B.OTB_REASON,
		          B.CHECK_TYPE,
		          B.CON_OTB_REQ,
		          B.CON_PREBOOK_LEV,
		          B.CON_DISTR_LEV ); 

 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_F_EKKO_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_EKKO_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_F_EKKO_SAP','DW','END';
END
	   
GO
/****** Object:  StoredProcedure [DW].[SP_F_EKPO_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_F_EKPO_SAP]
AS
	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50)
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_F_EKPO_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_F_EKPO_SAP', '', 'DW', 'Begin', '', '';
	
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_EKPO_SAP','','DW','Merge','F_EKPO_SAP','';

		MERGE INTO DW.F_EKPO_SAP A
		USING STG.STG_EKPO_Purchase_SAP B
		ON A.EBELN = B.EBELN
		   AND A.EBELP = B.EBELP
		WHEN MATCHED THEN
		  UPDATE SET A.MANDT = B.MANDT,
		             A.[LOEKZ] = B.[LOEKZ],
		             A.[MATNR] = B.[MATNR],
		             A.[EMATN] = B.[EMATN],
		             A.[BUKRS] = B.[BUKRS],
		             A.[WERKS] = B.[WERKS],
		             A.[LGORT] = B.[LGORT],
		             A.[INFNR] = B.[INFNR],
		             A.[KTMNG] = B.[KTMNG],
		             A.[MENGE] = B.[MENGE],
		             A.[MEINS] = B.[MEINS],
		             A.[NETPR] = B.[NETPR],
		             A.[PEINH] = B.[PEINH],
		             A.[NETWR] = B.[NETWR],
		             A.[BRTWR] = B.[BRTWR],
		             A.[SGT_SCAT] = B.[SGT_SCAT]
		WHEN NOT MATCHED THEN
		  INSERT( [MANDT],
		          [EBELN],
		          [EBELP],
		          [LOEKZ],
		          [MATNR],
		          [EMATN],
		          [BUKRS],
		          [WERKS],
		          [LGORT],
		          [INFNR],
		          [KTMNG],
		          [MENGE],
		          [MEINS],
		          [NETPR],
		          [PEINH],
		          [NETWR],
		          [BRTWR],
		          [SGT_SCAT] )
		  VALUES( B.[MANDT],
		          B.[EBELN],
		          B.[EBELP],
		          B.[LOEKZ],
		          B.[MATNR],
		          B.[EMATN],
		          B.[BUKRS],
		          B.[WERKS],
		          B.[LGORT],
		          B.[INFNR],
		          B.[KTMNG],
		          B.[MENGE],
		          B.[MEINS],
		          B.[NETPR],
		          B.[PEINH],
		          B.[NETWR],
		          B.[BRTWR],
		          B.[SGT_SCAT] ); 

	 
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_F_EKPO_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_EKPO_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_F_EKPO_SAP','DW','END';
END
	  
GO

/****** Object:  StoredProcedure [DW].[SP_F_STOCK_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_F_STOCK_SAP]
	--Load Stock from MCHB & MARD & EKES
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create

AS

	DECLARE	@v_err_num NUMERIC(18,0);
	DECLARE	@v_err_msg NVARCHAR(100);
	DECLARE @PROJECT_NAME varchar(50);
	DECLARE @V_CUR_DATE DATETIME;
	
	BEGIN
    SET @PROJECT_NAME = 'KAP';
    
	BEGIN TRY
		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_F_STOCK_SAP','DW','START';
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_F_STOCK_SAP', '', 'DW', 'Begin', '', '';
		
		SET @V_CUR_DATE = DATEADD(DAY,-1,CAST(DATEADD(HOUR,8,GETUTCDATE()) AS DATE));	--Yesterday
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_STOCK_SAP','','DW','Delete','F_STOCK_SAP',@V_CUR_DATE;
		
		DELETE FROM DW.F_STOCK_SAP WHERE STOCK_DATE = @V_CUR_DATE OR STOCK_DATE <= DATEADD(DAY,-40,@V_CUR_DATE);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_STOCK_SAP','','DW','Insert','F_STOCK_SAP','DC';
		
		INSERT INTO DW.F_STOCK_SAP( SKU_CODE,
			          STORE_CODE,
			          STORAGE_LOCATION,
			          BATCH_NO,
			          STOCK_DATE,
			          SKU_ID,
			          ARTICLE_ID,
			          STORE_ID,
			          STOCK_DATE_ID,
			          INVENTORY_CLASS,
			          UNRESTRICTED_USE_STOCK,
			          STOCK_IN_TRANSFER,
			          QUALITY_INSPECTION,
			          RESTRICTED_USE_STOCK,
			          BLOCKED_STOCK,
			          BLOCKED_STOCK_RETURNS,
			          SEGMENT,
			          RETAIL_PRICE,  
			          STANDARD_COST,
			          LOCAL_CURRENCY,
			          STANDARD_COST_GR,
			          STANDARD_COST_GR_USD,
			          SOURCE_TABLE
			           )
			   SELECT T.MATNR                                                               AS SKU_CODE,
			          STUFF(T.WERKS, 1, PATINDEX ('%[^0]%', T.WERKS) - 1, '')               AS STORE_CODE,
			          LGORT                                                                 AS STORAGE_LOCATION,
			          CHARG                                                                 AS BATCH_NO,
			          @V_CUR_DATE                                                           AS STOCK_DATE,
			          ISNULL(A1.SKU_ID, 0)                                                  AS SKU_ID,
			          ISNULL(A1.ARTICLE_ID, 0)                                              AS ARTICLE_ID,
			          ISNULL(S.SAPSTORE_ID, 0)                                              AS STORE_ID,
			          ISNULL(D.DATE_ID, 0)                                                  AS STOCK_DATE_ID,
			          I.INVENTORY_CLASS_DESC                                                AS INVENTORY_CLASS,
			          T.CLABS                                                               AS UNRESTRICTED_USE_STOCK,
			          0                                                                     AS STOCK_IN_TRANSFER,	--Get from EKES
			          T.CINSM                                                               AS QUALITY_INSPECTION,
			          T.CEINM                                                               AS RESTRICTED_USE_STOCK,
			          T.CSPEM                                                               AS BLOCKED_STOCK,
			          T.CRETM                                                               AS BLOCKED_STOCK_RETURNS,
			          T.SGT_SCAT                                                            AS SEGMENT,
			          ROUND((CASE S.SALES_ORGANIZATION WHEN '1130' THEN ISNULL(E.EX_RATE,1) ELSE 1 END) * P.RETAIL_PRICE, 4) AS RETAIL_PRICE,
			          C.STDCOST_AMT                                                         AS STANDARD_COST,
			          S.LOCAL_CURRENCY,
			          G.STDCOST_AMT                                                         AS STANDARD_COST_GR,
			          ROUND(G.STDCOST_AMT * ISNULL(E.EX_RATE,1),4)                          AS STANDARD_COST_GR_USD,
			          'MCHB'                                                                AS SOURCE_TABLE
			     FROM STG.STG_MCHB_Batch_SAP T
			          LEFT JOIN DW.D_ARTICLE_SIZE_SAP A1
			                 ON T.MATNR = A1.SAP_MATERIAL
			                    AND A1.IS_ACTIVE = 'Y'
			          LEFT JOIN DW.D_STORE_SAP S
			                 ON STUFF(T.WERKS, 1, PATINDEX ('%[^0]%', T.WERKS) - 1, '') = S.STORE_CODE
			          LEFT JOIN DW.D_DATE D
			                 ON @V_CUR_DATE = D.DAY_DATE
			          LEFT JOIN DW.D_INVENTORY_CLASS_SAP I
			                 ON T.MATNR = I.SAP_MATERIAL
			                    AND S.SALES_ORGANIZATION = I.SALES_ORGANIZATION
			                    AND S.DISTRIBUTION_CHANNEL = I.DISTRIBUTION_CHANNEL
			          LEFT JOIN DW.D_ARTICLE_PRICE_SAP P
			                 ON A1.GENERIC_ARTICLE = P.ARTICLE_NO
			                    AND P.CHANNEL = 'Retail'
			                    AND S.SALES_ORGANIZATION = P.SALES_ORG
			                    AND @V_CUR_DATE BETWEEN P.VALID_FROM_DATE AND P.VALID_TO_DATE
			                    AND S.LOCAL_CURRENCY = P.CURRENCY
			          LEFT JOIN DW.D_SKU_STDCOST_SAP C
			                 ON T.MATNR = C.MATERIAL_CODE
			                    AND STUFF(T.WERKS, 1, PATINDEX ('%[^0]%', T.WERKS) - 1, '') = C.STORE_CODE
			          LEFT JOIN DW.D_PRODUCT_COST_SAP G
			                 ON G.COST_TYPE = 'GR'
			                    AND T.MATNR = G.MATERIAL_CODE
			                    AND STUFF(T.WERKS, 1, PATINDEX ('%[^0]%', T.WERKS) - 1, '') = G.STORE_CODE
			                    AND @V_CUR_DATE BETWEEN G.EFFECTIVE_FROM_DATE AND G.EFFECTIVE_TO_DATE
			          LEFT JOIN DW.D_EXCHANGE_RATE_SAP E
			                 ON E.EX_RATE_TYPE = 'P'
			                    AND S.LOCAL_CURRENCY = E.FROM_CURRENCY
			                    AND E.TO_CURRENCY = 'USD'
			                    AND @V_CUR_DATE BETWEEN E.EFFECTIVE_DATE AND E.EFFECTIVE_END_DATE
			    WHERE T.CLABS <> 0 OR T.CINSM <> 0 OR T.CEINM <> 0 OR T.CSPEM <> 0 OR T.CRETM <> 0;
	  
	  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_STOCK_SAP','','DW','Insert','F_STOCK_SAP','Store';
	  
	  INSERT INTO DW.F_STOCK_SAP( SKU_CODE,
			          STORE_CODE,
			          STORAGE_LOCATION,
			          BATCH_NO,
			          STOCK_DATE,
			          SKU_ID,
			          ARTICLE_ID,
			          STORE_ID,
			          STOCK_DATE_ID,
			          INVENTORY_CLASS,
			          UNRESTRICTED_USE_STOCK,
			          STOCK_IN_TRANSFER,
			          QUALITY_INSPECTION,
			          RESTRICTED_USE_STOCK,
			          BLOCKED_STOCK,
			          BLOCKED_STOCK_RETURNS,
			          SEGMENT,
			          RETAIL_PRICE,  
			          STANDARD_COST,
			          LOCAL_CURRENCY,
			          STANDARD_COST_GR,
			          STANDARD_COST_GR_USD,
			          SOURCE_TABLE
			           )
			   SELECT T.MATNR                                                               AS SKU_CODE,
			          STUFF(T.WERKS, 1, PATINDEX ('%[^0]%', T.WERKS) - 1, '')               AS STORE_CODE,
			          LGORT                                                                 AS STORAGE_LOCATION,
			          ''                                                                    AS BATCH_NO,
			          @V_CUR_DATE                                                           AS STOCK_DATE,
			          ISNULL(A1.SKU_ID, 0)                                                  AS SKU_ID,
			          ISNULL(A1.ARTICLE_ID, 0)                                              AS ARTICLE_ID,
			          ISNULL(S.SAPSTORE_ID, 0)                                              AS STORE_ID,
			          ISNULL(D.DATE_ID, 0)                                                  AS STOCK_DATE_ID,
			          I.INVENTORY_CLASS_DESC                                                AS INVENTORY_CLASS,
			          T.LABST                                                               AS UNRESTRICTED_USE_STOCK,
			          0                                                                     AS STOCK_IN_TRANSFER,	--Get from EKES
			          T.INSME                                                               AS QUALITY_INSPECTION,
			          T.EINME                                                               AS RESTRICTED_USE_STOCK,
			          T.SPEME                                                               AS BLOCKED_STOCK,
			          T.RETME                                                               AS BLOCKED_STOCK_RETURNS,
			          ''                                                                    AS SEGMENT,
			          ROUND((CASE S.SALES_ORGANIZATION WHEN '1130' THEN ISNULL(E.EX_RATE,1) ELSE 1 END) * P.RETAIL_PRICE, 4) AS RETAIL_PRICE,
			          C.STDCOST_AMT                                                         AS STANDARD_COST,
			          S.LOCAL_CURRENCY,
			          G.STDCOST_AMT                                                         AS STANDARD_COST_GR,
			          ROUND(G.STDCOST_AMT * ISNULL(E.EX_RATE,1),4)                          AS STANDARD_COST_GR_USD,
			          'MARD'                                                                AS SOURCE_TABLE
			     FROM STG.STG_MARD_Stock_SAP T
			          LEFT JOIN DW.D_ARTICLE_SIZE_SAP A1
			                 ON T.MATNR = A1.SAP_MATERIAL
			                    AND A1.IS_ACTIVE = 'Y'
			          LEFT JOIN DW.D_STORE_SAP S
			                 ON STUFF(T.WERKS, 1, PATINDEX ('%[^0]%', T.WERKS) - 1, '') = S.STORE_CODE
			          LEFT JOIN DW.D_DATE D
			                 ON @V_CUR_DATE = D.DAY_DATE
			          LEFT JOIN DW.D_INVENTORY_CLASS_SAP I
			                 ON T.MATNR = I.SAP_MATERIAL
			                    AND S.SALES_ORGANIZATION = I.SALES_ORGANIZATION
			                    AND S.DISTRIBUTION_CHANNEL = I.DISTRIBUTION_CHANNEL
			          LEFT JOIN DW.D_ARTICLE_PRICE_SAP P
			                 ON A1.GENERIC_ARTICLE = P.ARTICLE_NO
			                    AND P.CHANNEL = 'Retail'
			                    AND S.SALES_ORGANIZATION = P.SALES_ORG
			                    AND @V_CUR_DATE BETWEEN P.VALID_FROM_DATE AND P.VALID_TO_DATE
			                    AND S.LOCAL_CURRENCY = P.CURRENCY
			          LEFT JOIN DW.D_SKU_STDCOST_SAP C
			                 ON T.MATNR = C.MATERIAL_CODE
			                    AND STUFF(T.WERKS, 1, PATINDEX ('%[^0]%', T.WERKS) - 1, '') = C.STORE_CODE
			          LEFT JOIN DW.D_PRODUCT_COST_SAP G
			                 ON G.COST_TYPE = 'GR'
			                    AND T.MATNR = G.MATERIAL_CODE
			                    AND STUFF(T.WERKS, 1, PATINDEX ('%[^0]%', T.WERKS) - 1, '') = G.STORE_CODE
			                    AND @V_CUR_DATE BETWEEN G.EFFECTIVE_FROM_DATE AND G.EFFECTIVE_TO_DATE
			          LEFT JOIN DW.D_EXCHANGE_RATE_SAP E
			                 ON E.EX_RATE_TYPE = 'P'
			                    AND S.LOCAL_CURRENCY = E.FROM_CURRENCY
			                    AND E.TO_CURRENCY = 'USD'
			                    AND @V_CUR_DATE BETWEEN E.EFFECTIVE_DATE AND E.EFFECTIVE_END_DATE
			    WHERE (T.LABST <> 0 OR T.INSME <> 0 OR T.EINME <> 0 OR T.SPEME <> 0 OR T.RETME <> 0)
				AND ISNULL(S.STORE_CATEGORY_DESC,'X')<>'DC';
			    
	  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_STOCK_SAP','','DW','Insert','F_STOCK_SAP','Stk in trans';
	  
	  WITH T_STK_IN_TRANS AS 
			   	(SELECT P.MATNR,P.WERKS,P.SGT_SCAT,SUM(T.MENGE)-SUM(T.DABMG) AS STK_IN_TRANS 
						FROM DW.F_EKES_SAP T
								 INNER JOIN DW.F_EKPO_SAP P
								    ON T.EBELN = P.EBELN
								       AND T.EBELP = P.EBELP
								 INNER JOIN DW.F_EKKO_SAP K
								    ON T.EBELN = K.EBELN
					 WHERE T.EBTYP = 'LA'
						 AND K.BSART IN ('ZICS','ZINS')	--PO_TYPE
					 GROUP BY P.MATNR,P.WERKS,P.SGT_SCAT
					 HAVING SUM(T.MENGE) <> SUM(T.DABMG))
	  INSERT INTO DW.F_STOCK_SAP( SKU_CODE,
			          STORE_CODE,
			          STORAGE_LOCATION,
			          BATCH_NO,
			          STOCK_DATE,
			          SKU_ID,
			          ARTICLE_ID,
			          STORE_ID,
			          STOCK_DATE_ID,
			          INVENTORY_CLASS,
			          STOCK_IN_TRANSFER,
			          SEGMENT,
			          RETAIL_PRICE,  
			          STANDARD_COST,
			          LOCAL_CURRENCY,
			          STANDARD_COST_GR,
			          STANDARD_COST_GR_USD,
			          SOURCE_TABLE
			           )
			   SELECT T.MATNR                                                               AS SKU_CODE,
			          T.WERKS                                                               AS STORE_CODE,
			          ''                                                                    AS STORAGE_LOCATION,
			          T.SGT_SCAT                                                            AS BATCH_NO,
			          @V_CUR_DATE                                                           AS STOCK_DATE,
			          ISNULL(A1.SKU_ID, 0)                                                  AS SKU_ID,
			          ISNULL(A1.ARTICLE_ID, 0)                                              AS ARTICLE_ID,
			          ISNULL(S.SAPSTORE_ID, 0)                                              AS STORE_ID,
			          ISNULL(D.DATE_ID, 0)                                                  AS STOCK_DATE_ID,
			          I.INVENTORY_CLASS_DESC                                                AS INVENTORY_CLASS,
			          T.STK_IN_TRANS                                                        AS STOCK_IN_TRANSFER,
			          T.SGT_SCAT                                                            AS SEGMENT,
			          ROUND((CASE S.SALES_ORGANIZATION WHEN '1130' THEN ISNULL(E.EX_RATE,1) ELSE 1 END) * P.RETAIL_PRICE, 4) AS RETAIL_PRICE,
			          C.STDCOST_AMT                                                         AS STANDARD_COST,
			          S.LOCAL_CURRENCY,
			          G.STDCOST_AMT                                                         AS STANDARD_COST_GR,
			          ROUND(G.STDCOST_AMT * ISNULL(E.EX_RATE,1),4)                          AS STANDARD_COST_GR_USD,
			          'EKES'                                                                AS SOURCE_TABLE
			     FROM T_STK_IN_TRANS T
			          LEFT JOIN DW.D_ARTICLE_SIZE_SAP A1
			                 ON T.MATNR = A1.SAP_MATERIAL
			                    AND A1.IS_ACTIVE = 'Y'
			          LEFT JOIN DW.D_STORE_SAP S
			                 ON T.WERKS = S.STORE_CODE
			          LEFT JOIN DW.D_DATE D
			                 ON @V_CUR_DATE = D.DAY_DATE
			          LEFT JOIN DW.D_INVENTORY_CLASS_SAP I
			                 ON T.MATNR = I.SAP_MATERIAL
			                    AND S.SALES_ORGANIZATION = I.SALES_ORGANIZATION
			                    AND S.DISTRIBUTION_CHANNEL = I.DISTRIBUTION_CHANNEL
			          LEFT JOIN DW.D_ARTICLE_PRICE_SAP P
			                 ON A1.GENERIC_ARTICLE = P.ARTICLE_NO
			                    AND P.CHANNEL = 'Retail'
			                    AND S.SALES_ORGANIZATION = P.SALES_ORG
			                    AND @V_CUR_DATE BETWEEN P.VALID_FROM_DATE AND P.VALID_TO_DATE
			                    AND S.LOCAL_CURRENCY = P.CURRENCY
			          LEFT JOIN DW.D_SKU_STDCOST_SAP C
			                 ON T.MATNR = C.MATERIAL_CODE
			                    AND T.WERKS = C.STORE_CODE
			          LEFT JOIN DW.D_PRODUCT_COST_SAP G
			                 ON G.COST_TYPE = 'GR'
			                    AND T.MATNR = G.MATERIAL_CODE
			                    AND T.WERKS = G.STORE_CODE
			                    AND @V_CUR_DATE BETWEEN G.EFFECTIVE_FROM_DATE AND G.EFFECTIVE_TO_DATE
			          LEFT JOIN DW.D_EXCHANGE_RATE_SAP E
			                 ON E.EX_RATE_TYPE = 'P'
			                    AND S.LOCAL_CURRENCY = E.FROM_CURRENCY
			                    AND E.TO_CURRENCY = 'USD'
			                    AND @V_CUR_DATE BETWEEN E.EFFECTIVE_DATE AND E.EFFECTIVE_END_DATE;
	  
	  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_STOCK_SAP','','DW','Insert','F_STOCK_SAP','Consignment Stock';
	  
	  WITH T_CONSIGNMENT_STOCK AS 
			   	(SELECT T.MATBF,T.WERKS,T.CHARG_SID,T.SGT_SCAT,SUM(T.STOCK_QTY_L1) AS STOCK_QTY_L1 
						FROM STG.STG_MATDOC_EXTRACT_Stock_SAP T
					 WHERE T.KUNNR_SID <> ''
					 AND T.LBBSA_SID = '01'
					 AND T.SOBKZ IN ( 'W', 'V' )
					 GROUP BY T.MATBF,T.WERKS,T.CHARG_SID,T.SGT_SCAT
					 HAVING SUM(T.STOCK_QTY_L1) <> 0)
	  MERGE INTO DW.F_STOCK_SAP T
	  	USING ( SELECT T.MATBF                                                               AS SKU_CODE,
			    		       T.WERKS                                                               AS STORE_CODE,
			    		       '0001'                                                                AS STORAGE_LOCATION,
			    		       T.CHARG_SID                                                           AS BATCH_NO,
			    		       @V_CUR_DATE                                                           AS STOCK_DATE,
			    		       ISNULL(A1.SKU_ID, 0)                                                  AS SKU_ID,
			    		       ISNULL(A1.ARTICLE_ID, 0)                                              AS ARTICLE_ID,
			    		       ISNULL(S.SAPSTORE_ID, 0)                                              AS STORE_ID,
			    		       ISNULL(D.DATE_ID, 0)                                                  AS STOCK_DATE_ID,
			    		       I.INVENTORY_CLASS_DESC                                                AS INVENTORY_CLASS,
			    		       T.STOCK_QTY_L1                                                        AS CONSIGNMENT_STOCK,
			    		       T.SGT_SCAT                                                            AS SEGMENT,
			    		       ROUND((CASE S.SALES_ORGANIZATION WHEN '1130' THEN ISNULL(E.EX_RATE,1) ELSE 1 END) * P.RETAIL_PRICE, 4) AS RETAIL_PRICE,
			    		       C.STDCOST_AMT                                                         AS STANDARD_COST,
			    		       S.LOCAL_CURRENCY,
			    		       G.STDCOST_AMT                                                         AS STANDARD_COST_GR,
			    		       ROUND(G.STDCOST_AMT * ISNULL(E.EX_RATE,1),4)                          AS STANDARD_COST_GR_USD,
			    		       'MATDOC_EXTRACT'                                                      AS SOURCE_TABLE
			    		  FROM T_CONSIGNMENT_STOCK T
			    		       LEFT JOIN DW.D_ARTICLE_SIZE_SAP A1
			    		              ON T.MATBF = A1.SAP_MATERIAL
			    		                 AND A1.IS_ACTIVE = 'Y'
			    		       LEFT JOIN DW.D_STORE_SAP S
			    		              ON T.WERKS = S.STORE_CODE
			    		       LEFT JOIN DW.D_DATE D
			    		              ON @V_CUR_DATE = D.DAY_DATE
			    		       LEFT JOIN DW.D_INVENTORY_CLASS_SAP I
			    		              ON T.MATBF = I.SAP_MATERIAL
			    		                 AND S.SALES_ORGANIZATION = I.SALES_ORGANIZATION
			    		                 AND S.DISTRIBUTION_CHANNEL = I.DISTRIBUTION_CHANNEL
			    		       LEFT JOIN DW.D_ARTICLE_PRICE_SAP P
			    		              ON A1.GENERIC_ARTICLE = P.ARTICLE_NO
			    		                 AND P.CHANNEL = 'Retail'
			    		                 AND S.SALES_ORGANIZATION = P.SALES_ORG
			    		                 AND @V_CUR_DATE BETWEEN P.VALID_FROM_DATE AND P.VALID_TO_DATE
			    		                 AND S.LOCAL_CURRENCY = P.CURRENCY
			    		       LEFT JOIN DW.D_SKU_STDCOST_SAP C
			    		              ON T.MATBF = C.MATERIAL_CODE
			    		                 AND T.WERKS = C.STORE_CODE
			    		       LEFT JOIN DW.D_PRODUCT_COST_SAP G
			    		              ON G.COST_TYPE = 'GR'
			    		                 AND T.MATBF = G.MATERIAL_CODE
			    		                 AND T.WERKS = G.STORE_CODE
			    		                 AND @V_CUR_DATE BETWEEN G.EFFECTIVE_FROM_DATE AND G.EFFECTIVE_TO_DATE
			    		       LEFT JOIN DW.D_EXCHANGE_RATE_SAP E
			    		              ON E.EX_RATE_TYPE = 'P'
			    		                 AND S.LOCAL_CURRENCY = E.FROM_CURRENCY
			    		                 AND E.TO_CURRENCY = 'USD'
			    		                 AND @V_CUR_DATE BETWEEN E.EFFECTIVE_DATE AND E.EFFECTIVE_END_DATE) S
			ON T.SKU_CODE = S.SKU_CODE
			AND T.STORE_CODE = S.STORE_CODE
			AND T.STORAGE_LOCATION = S.STORAGE_LOCATION
			AND T.BATCH_NO = S.BATCH_NO
			AND T.STOCK_DATE = S.STOCK_DATE
			WHEN MATCHED THEN UPDATE 
						SET T.CONSIGNMENT_STOCK = S.CONSIGNMENT_STOCK
			WHEN NOT MATCHED THEN INSERT (SKU_CODE,
			          STORE_CODE,
			          STORAGE_LOCATION,
			          BATCH_NO,
			          STOCK_DATE,
			          SKU_ID,
			          ARTICLE_ID,
			          STORE_ID,
			          STOCK_DATE_ID,
			          INVENTORY_CLASS,
			          CONSIGNMENT_STOCK,
			          SEGMENT,
			          RETAIL_PRICE,  
			          STANDARD_COST,
			          LOCAL_CURRENCY,
			          STANDARD_COST_GR,
			          STANDARD_COST_GR_USD,
			          SOURCE_TABLE
			           )
			   VALUES (S.SKU_CODE,
			           S.STORE_CODE,
			           S.STORAGE_LOCATION,
			           S.BATCH_NO,
			           S.STOCK_DATE,
			           S.SKU_ID,
			           S.ARTICLE_ID,
			           S.STORE_ID,
			           S.STOCK_DATE_ID,
			           S.INVENTORY_CLASS,
			           S.CONSIGNMENT_STOCK,
			           S.SEGMENT,
			           S.RETAIL_PRICE,  
			           S.STANDARD_COST,
			           S.LOCAL_CURRENCY,
			           S.STANDARD_COST_GR,
			           S.STANDARD_COST_GR_USD,
			           S.SOURCE_TABLE);
			                    
	  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_STOCK_SAP','','DW','Update','STANDARD_COST_GR','';
		
		--China: Use STD cost(Group) of DC
		UPDATE T
		SET STANDARD_COST_GR = G.STDCOST_AMT,
				STANDARD_COST_GR_USD = ROUND(G.STDCOST_AMT * ISNULL(E.EX_RATE,1),4)
		FROM DW.F_STOCK_SAP T
		INNER JOIN DW.D_STORE_SAP S
			ON T.STORE_CODE = S.STORE_CODE
		INNER JOIN DW.D_PRODUCT_COST_SAP G
		  ON	G.COST_TYPE = 'GR'
				AND (CASE S.SALES_ORGANIZATION WHEN '1050' THEN '9111' WHEN '1060' THEN '1161' END) = G.STORE_CODE
				AND T.SKU_CODE = G.MATERIAL_CODE
				AND T.STOCK_DATE BETWEEN G.EFFECTIVE_FROM_DATE AND G.EFFECTIVE_TO_DATE
		LEFT JOIN DW.D_EXCHANGE_RATE_SAP E
			ON E.EX_RATE_TYPE = 'P'
			   AND T.LOCAL_CURRENCY = E.FROM_CURRENCY
			   AND E.TO_CURRENCY = 'USD'
			   AND T.STOCK_DATE BETWEEN E.EFFECTIVE_DATE AND E.EFFECTIVE_END_DATE
		WHERE 1=1
		--AND S.SALES_ORGANIZATION IN ('1050','1060')	--China
		AND T.STANDARD_COST_GR IS NULL
		AND T.STOCK_DATE = @V_CUR_DATE;
				
		--Hong Kong & India: Use STD cost(Legel)
		UPDATE T
		SET STANDARD_COST_GR = T.STANDARD_COST,
				STANDARD_COST_GR_USD = ROUND(T.STANDARD_COST * ISNULL(E.EX_RATE,1),4)
		FROM DW.F_STOCK_SAP T
		INNER JOIN DW.D_STORE_SAP S
			ON T.STORE_CODE = S.STORE_CODE
		LEFT JOIN DW.D_EXCHANGE_RATE_SAP E
			ON E.EX_RATE_TYPE = 'P'
			   AND T.LOCAL_CURRENCY = E.FROM_CURRENCY
			   AND E.TO_CURRENCY = 'USD'
			   AND T.STOCK_DATE BETWEEN E.EFFECTIVE_DATE AND E.EFFECTIVE_END_DATE
		WHERE 1=1
		--AND S.SALES_ORGANIZATION IN ('1130','1150')	--Hong Kong & India
		AND T.STANDARD_COST_GR IS NULL
		AND T.STOCK_DATE = @V_CUR_DATE;	  
	  
 		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_F_STOCK_SAP', '', 'DW', 'End', '', '';

END TRY
BEGIN CATCH
		SET @v_err_num = ERROR_NUMBER();
		SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);
		
		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_F_STOCK_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';
		
END CATCH;

EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_F_STOCK_SAP','DW','END';
END    


GO

/****** Object:  StoredProcedure [LD].[SP_LD_ARTICLE_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [LD].[SP_LD_ARTICLE_SAP]
  --Load data from staging to loading
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create
AS

    DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @FILE_ID INT
    DECLARE @PROJECT_NAME varchar(50)

BEGIN

SELECT @PROJECT_NAME = 'KAP';

  BEGIN TRY
      
       --Begin log
       EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_ARTICLE_SAP','LD','START';
       EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_ARTICLE_SAP', '', 'LD', 'Begin', '', '';
       
       EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_ARTICLE_SAP', '', 'MESSAGE', 'Update', 'STG_MARA_Material_SAP', '';
       
			 UPDATE STG.STG_MARA_Material_SAP
			    SET SATNR = MATNR
			  WHERE SATNR = ''; 
        
       TRUNCATE TABLE LD.LD_ARTICLE_SAP
         
       EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_ARTICLE_SAP', '', 'MESSAGE', 'Merge', 'LD_ARTICLE_SAP', '';

				--Update loading table data
				MERGE INTO LD.LD_ARTICLE_SAP A
				USING (SELECT *
				         FROM(SELECT M.MATNR                                                 AS SKU_CODE,
				                     M.EAN11                                                 AS C19_0EANUPC,
				                     M.MATKL                                                 AS MATERIAL_GROUP,
				                     ISNULL(B.BRAND_NAME, 'NA')                              AS BRAND,
				                     ISNULL(B.BRAND_ID, 0)                                   AS BRAND_ID,
				                     M.SIZE2                                                 AS C52_0RF_SIZE2,
				                     ISNULL(F.FSH_SEASON, '')                                AS CURRENT_SEASON,
				                     ISNULL(F.FSH_SEASON_YEAR, '')                           AS CURRENT_SEASON_YEAR,
				                     M.SIZE1                                                 AS C68_0RT_SIZE,
				                     M.COLOR                                                 AS C90_ZCOLC,
				                     F.FSH_COLLECTION                                        AS COLLECTION,
				                     M.LABOR                                                 AS C96_ZDESO,
				                     M.FSH_MG_AT3                                            AS GENDER,
				                     M.SATNR                                                 AS GENERIC_ARTICLE,
				                     M.MTART                                                 AS C44_0MATL_TYPE,
				                     M.PLGTP                                                 AS C62_0RT_PRBAND,
				                     M.FUELG                                                 AS C101_ZFILLG,
				                     M.MEINS                                                 AS C8_0BASE_UOM,
				                     M.SPART                                                 AS DIVISION,
				                     F1.FSH_SEASON AS BIRTH,
				                     F1.FSH_SEASON_YEAR AS BIRTH_YEAR,
				                     ROW_NUMBER()
				                       OVER(
				                         PARTITION BY M.MATNR
				                         ORDER BY F.FSH_SEASON_YEAR DESC, CASE F.FSH_SEASON WHEN 'FW' THEN 1 WHEN 'SS' THEN 2 ELSE 3 END) RID
				                FROM STG.STG_MARA_Material_SAP M
				                     INNER JOIN DW.D_FSHSEASONSMAT_SAP F
				                            ON M.SATNR = F.MATNR
				                     LEFT JOIN (SELECT MATNR, FSH_SEASON_YEAR, FSH_SEASON, 
				                     									 ROW_NUMBER() OVER(PARTITION BY MATNR ORDER BY FSH_SEASON_YEAR, CASE FSH_SEASON WHEN 'SS' THEN 1 WHEN 'FW' THEN 2 ELSE 3 END) RID 
				                     							FROM DW.D_FSHSEASONSMAT_SAP) F1
				                     				ON M.SATNR = F1.MATNR AND F1.RID = 1
				                     LEFT JOIN DW.D_BRAND B
				                            ON M.BRAND_ID = B.SAP_SHORT_BRAND
				               WHERE M.MATNR <> '')T
				        WHERE T.RID = 1) B
				ON ( A.GENERIC_ARTICLE = B.GENERIC_ARTICLE
				     AND A.CURRENT_SEASON = B.CURRENT_SEASON
				     AND A.CURRENT_YEAR = B.CURRENT_SEASON_YEAR
				     AND A.C1_0MATERIAL = B.SKU_CODE )
				WHEN MATCHED THEN
				  UPDATE SET --A.GENERIC_ARTICLE                = B.GENERIC_ARTICLE,
										 --A.C1_0MATERIAL                   = B.SKU_CODE,
										 A.MERCHANDISE_CATEGORY_CODE = B.MATERIAL_GROUP,
										 --A.CURRENT_SEASON                 = B.CURRENT_SEASON,
										 --A.CURRENT_YEAR                   = B.CURRENT_SEASON_YEAR,
										 A.BIRTH = B.BIRTH,
										 A.BIRTH_YEAR = B.BIRTH_YEAR,
										 A.C19_0EANUPC = B.C19_0EANUPC,
										 A.C68_0RT_SIZE = B.C68_0RT_SIZE,
										 A.C52_0RF_SIZE2 = B.C52_0RF_SIZE2,
										 A.COLOR_CODE = B.C90_ZCOLC,
										 A.GENDER_CODE = B.GENDER,
										 A.DESIGN_OFFICE = B.C96_ZDESO,
										 A.COLLECTION = B.COLLECTION,
										 A.BRAND = B.BRAND,
										 A.BRAND_ID = B.BRAND_ID,
										 A.ARTICLE_TYPE = B.C44_0MATL_TYPE,
										 A.PRICE_BAND_CATEGORY = B.C62_0RT_PRBAND,
										 A.FILLING_DESC = B.C101_ZFILLG,
										 A.BASE_UNIT_OF_MEASURE = B.C8_0BASE_UOM,
										 A.DIVISION = B.DIVISION,
										 A.MATERIAL_GROUP = B.MATERIAL_GROUP
				WHEN NOT MATCHED THEN
				  INSERT (GENERIC_ARTICLE,
				          C1_0MATERIAL,
				          C19_0EANUPC,
				          C68_0RT_SIZE,
				          C52_0RF_SIZE2,
				          MERCHANDISE_CATEGORY_CODE,
				          CURRENT_SEASON,
				          CURRENT_YEAR,
				          BIRTH,
				          BIRTH_YEAR,
				          COLOR_CODE,
				          GENDER_CODE,
				          DESIGN_OFFICE,
				          COLLECTION,
				          BRAND,
				          BRAND_ID,
				          ARTICLE_TYPE,
				          PRICE_BAND_CATEGORY,
				          FILLING_DESC,
				          BASE_UNIT_OF_MEASURE,
				          DIVISION,
				          MATERIAL_GROUP)
				  VALUES (B.GENERIC_ARTICLE,
				          B.SKU_CODE,
				          B.C19_0EANUPC,
				          B.C68_0RT_SIZE,
				          B.C52_0RF_SIZE2,
				          B.MATERIAL_GROUP,
				          B.CURRENT_SEASON,
				          B.CURRENT_SEASON_YEAR,
				          B.BIRTH,
				          B.BIRTH_YEAR,
				          B.C90_ZCOLC,
				          B.GENDER,
				          B.C96_ZDESO,
				          B.COLLECTION,
				          B.BRAND,
				          B.BRAND_ID,
				          B.C44_0MATL_TYPE,
				          B.C62_0RT_PRBAND,
				          B.C101_ZFILLG,
				          B.C8_0BASE_UOM,
				          B.DIVISION,
				          B.MATERIAL_GROUP); 
          
		  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_ARTICLE_SAP','','MESSAGE','Update','GENDER DESC','';
			
			UPDATE T
			   SET ARTICLE_DESC = S.ARTICLE_DESC,
			       CHINESE_DESC = S.CHINESE_DESC
			  FROM LD.LD_ARTICLE_SAP T
			       LEFT JOIN DW.D_ARTICLE_DESC_SAP S
			              ON T.C1_0MATERIAL = S.SAP_MATERIAL;                   
                   
      UPDATE LD.LD_ARTICLE_SAP
         SET SAP_GENDER_DESC =
                ISNULL (
                   (SELECT SAP_DESC
                      FROM DW.D_KEYDATA_SAP B
                     WHERE     CODE_TYPE = 'GENDER'
                           AND B.LANG = 'E'
                           AND B.SAP_CODE = GENDER_CODE),
                   SAP_GENDER_DESC);	
      
      EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_ARTICLE_SAP','','MESSAGE','Update','Product Group','';
      
			UPDATE T
			   SET T.PRODUCT_GROUP = K2.KSCHL
			  FROM LD.LD_ARTICLE_SAP T
			       LEFT JOIN DW.D_KLAH_SAP K1
			              ON K1.KLART = '026'
			                 AND K1.CLASS = LEFT(T.MATERIAL_GROUP, 4)
			       LEFT JOIN DW.D_SWOR_SAP K2
			              ON K1.CLINT = K2.CLINT
			              AND K2.SPRAS = 'E'; 
			
			UPDATE T
			   SET T.PRODUCT_SUB_GROUP = K2.KSCHL
			  FROM LD.LD_ARTICLE_SAP T
			       LEFT JOIN DW.D_KLAH_SAP K1
			              ON K1.KLART = '026'
			                 AND K1.CLASS = LEFT(T.MATERIAL_GROUP, 6)
			       LEFT JOIN DW.D_SWOR_SAP K2
			              ON K1.CLINT = K2.CLINT
			              AND K2.SPRAS = 'E';

			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_ARTICLE_SAP','','MESSAGE','Update','Article Hierarchy','';
      
			UPDATE T
			   SET T.SUB_BRAND = K2.LTEXT,
			       T.CONCEPT = K3.LTEXT,
			       T.STORY = K4.LTEXT,
			       T.TIER = K5.LTEXT
			  FROM LD.LD_ARTICLE_SAP T
			       LEFT JOIN DW.D_WRFMATGRPSKU_SAP K1
			              ON K1.HIER_ID = 'K1'
			                 AND T.C1_0MATERIAL = K1.MATNR
			       LEFT JOIN DW.D_WRF_MATGRP_STRCT_SAP K2
			              ON LEFT(K1.NODE, 4) = K2.NODE
			       LEFT JOIN DW.D_WRF_MATGRP_STRCT_SAP K3
			              ON LEFT(K1.NODE, 7) = K3.NODE
			       LEFT JOIN DW.D_WRF_MATGRP_STRCT_SAP K4
			              ON LEFT(K1.NODE, 10) = K4.NODE
			       LEFT JOIN DW.D_WRF_MATGRP_STRCT_SAP K5
			              ON K1.NODE = K5.NODE; 

			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_ARTICLE_SAP','','MESSAGE','Update','Article Mapping','';

			UPDATE STG.STG_MARA_Material_SAP
			SET BISMT=CASE WHEN ISNULL(A.BISMT,'')<>'' THEN A.BISMT 
	            ELSE A.ZZMONAM+STUFF(RIGHT(A.ZZFABCD,6),1,PATINDEX('%[^0]%',RIGHT(A.ZZFABCD,6))-1,'')+C.ZDESC END
			FROM STG.STG_MARA_Material_SAP A
			INNER JOIN STG.STG_FSHSEASONSMAT_Material_SAP B
				ON A.MATNR=B.MATNR
			LEFT JOIN STG.STG_ZPTP_T_WASHC_SAP C
				ON A.ZZWASHC=C.CODE
			WHERE B.FSH_SEASON_YEAR='2021'
			AND B.FSH_SEASON='FW'
			AND A.MTART='ZMDE'
			OR B.FSH_SEASON_YEAR>'2021' AND A.MTART='ZMDE'		


			SELECT DISTINCT MATNR AS GENERIC_ARTICLE,BISMT AS GENERIC_ARTICLE_OLD
			INTO #TEMPAR
			FROM STG.STG_MARA_Material_SAP
			WHERE MATNR=SATNR
			AND BISMT<>''
/*
			UPDATE DW.D_ARTICLE_MAPPING
			SET NEW_ARTICLE=T.GENERIC_ARTICLE
			FROM DW.D_ARTICLE_MAPPING A
			INNER JOIN #TEMPAR T
				ON A.OLD_ARTICLE=T.GENERIC_ARTICLE_OLD
				AND A.NEW_ARTICLE<>T.GENERIC_ARTICLE
*/
			INSERT INTO DW.D_ARTICLE_MAPPING(
			NEW_ARTICLE,OLD_ARTICLE
			)
			SELECT DISTINCT A.GENERIC_ARTICLE, GENERIC_ARTICLE_OLD
			FROM #TEMPAR A
			WHERE NOT EXISTS (
				SELECT 1 FROM DW.D_ARTICLE_MAPPING WHERE NEW_ARTICLE=A.GENERIC_ARTICLE --AND OLD_ARTICLE=A.GENERIC_ARTICLE_OLD
			)



			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_ARTICLE_SAP','','MESSAGE','Update','SKU Mapping','';

			SELECT DISTINCT MATNR AS SKU_CODE,BISMT AS SKU_CODE_OLD
			INTO #TEMPSK
			FROM STG.STG_MARA_Material_SAP
			WHERE MATNR<>SATNR
			AND BISMT<>''

			INSERT INTO DW.D_SKU_MAPPING(
			NEW_SKU_CODE,OLD_SKU_CODE
			)
			SELECT A.SKU_CODE, SKU_CODE_OLD
			FROM #TEMPSK A
			WHERE NOT EXISTS (
				SELECT 1 FROM DW.D_SKU_MAPPING WHERE NEW_SKU_CODE=A.SKU_CODE AND OLD_SKU_CODE=A.SKU_CODE_OLD
			)	
		

      EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_ARTICLE_SAP', '', 'LD', 'End', '', '';
       
    END TRY

    BEGIN CATCH
  

        SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
               @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

        SET @v_msg='FILE_ID:'+CAST(@FILE_ID AS VARCHAR(20));

       EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_ARTICLE_SAP', '', 'EXCEPTION', @v_msg, @errorcode, @errormsg;
       
    END CATCH
    
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_ARTICLE_SAP','LD','END';
    
 END

GO
/****** Object:  StoredProcedure [LD].[SP_LD_DATE_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [LD].[SP_LD_DATE_SAP]
  --Load data from staging to loading
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create
AS

    DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @PROJECT_NAME varchar(50)
    DECLARE @FILE_ID INT
    DECLARE @FISCAL_DAY DATE
    DECLARE @FISCAL_YEAR NVARCHAR(4)
    DECLARE @FISCAL_MONTH NVARCHAR(2)
		
BEGIN

SELECT @PROJECT_NAME = 'KAP';
        
  BEGIN TRY
		--Begin log
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_DATE_SAP','LD','START';
    EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_DATE_SAP','','MESSAGE','Begin','','';
    EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_DATE_SAP','','MESSAGE','Delete&Insert','LD_ZFISDAY_SAP','';
    
    TRUNCATE TABLE LD.LD_ZFISDAY_SAP;
        
		--INSERT INTO change to MERGE INTO 
		MERGE INTO LD.LD_ZFISDAY_SAP A
		USING (SELECT CAST(CONCAT(S.BDATJ, S.BUMON, S.BUTAG) AS DATE) AS FISCAL_DAY,
		              CAST(S.BDATJ AS INT)
		              + CAST(S.RELJR AS INT)                          AS FISCAL_YEAR,
		              RIGHT(S.POPER, 2)                               AS FISCAL_MONTH
		         FROM STG.STG_T009B_Fiscal_SAP S
		        WHERE S.PERIV = 'Z1'
		              AND DATEPART(WEEKDAY, CAST(CONCAT(S.BDATJ, S.BUMON, S.BUTAG) AS DATE)) = 7 --filter out end date is not Sunday
		              AND S.BDATJ > '2005'
		              AND S.BDATJ <= DATEPART(YEAR, GETDATE()) + 1) B
		ON A.FISCAL_DAY = B.FISCAL_DAY
		WHEN MATCHED THEN
		  UPDATE SET FISCAL_YEAR = B.FISCAL_YEAR,
		             FISCAL_MONTH = B.FISCAL_MONTH
		WHEN NOT MATCHED THEN
		  INSERT( FISCAL_DAY,
		          FISCAL_YEAR,
		          FISCAL_MONTH )
		  VALUES( B.FISCAL_DAY,
		          B.FISCAL_YEAR,
		          B.FISCAL_MONTH ); 

		EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_DATE_SAP','','MESSAGE','Insert','Fullfill Days in calendar','';
		
		DECLARE @V_FISCAL_DAY DATE
		DECLARE @V_FISCAL_YEAR NVARCHAR(4)
		DECLARE @V_FISCAL_MONTH NVARCHAR(2)
		DECLARE C_FILE CURSOR FOR
		  SELECT FISCAL_DAY,
		         FISCAL_YEAR,
		         FISCAL_MONTH
		    FROM LD.LD_ZFISDAY_SAP
		   ORDER BY FISCAL_DAY
		
		OPEN C_FILE
		
		FETCH NEXT FROM C_FILE INTO @V_FISCAL_DAY, @V_FISCAL_YEAR, @V_FISCAL_MONTH
		
		WHILE @@FETCH_STATUS = 0
		  BEGIN
		  	
		      WHILE @V_FISCAL_DAY > DATEADD(DAY, 1, @FISCAL_DAY)
		        BEGIN
		            SET @FISCAL_DAY = DATEADD(DAY, 1, @FISCAL_DAY);
		            
		            INSERT INTO LD.LD_ZFISDAY_SAP
		                        (FISCAL_DAY,
		                         FISCAL_YEAR,
		                         FISCAL_MONTH)
		                 VALUES(@FISCAL_DAY,
		                        @V_FISCAL_YEAR,
		                        @V_FISCAL_MONTH)
 
		        END
		
		      SET @FISCAL_DAY = @V_FISCAL_DAY;
		      SET @FISCAL_YEAR = @V_FISCAL_YEAR;
		      SET @FISCAL_MONTH = @V_FISCAL_MONTH;
		
		      FETCH NEXT FROM C_FILE INTO @V_FISCAL_DAY, @V_FISCAL_YEAR, @V_FISCAL_MONTH
		  END
		
		CLOSE C_FILE
		
		DEALLOCATE C_FILE
		
		--Update week info
		MERGE INTO LD.LD_ZFISDAY_SAP A
		USING (SELECT FISCAL_DAY,
		              CASE
		                WHEN FISCAL_MONTH BETWEEN '01' AND '06' THEN 1
		                WHEN FISCAL_MONTH BETWEEN '07' AND '12' THEN 2
		              END                               AS FISCAL_HALFY,
		              CASE
		                WHEN FISCAL_MONTH IN ( '01', '02', '03' ) THEN 1
		                WHEN FISCAL_MONTH IN ( '04', '05', '06' ) THEN 2
		                WHEN FISCAL_MONTH IN ( '07', '08', '09' ) THEN 3
		                WHEN FISCAL_MONTH IN ( '10', '11', '12' ) THEN 4
		              END                               AS FISCAL_QUARTER,
		              CONCAT(FISCAL_YEAR, FISCAL_MONTH) AS FISCAL_MONTH2,
		              RIGHT(CONCAT('0', DATEDIFF(wk, FIRST_VALUE(FISCAL_DAY) OVER(PARTITION BY FISCAL_YEAR ORDER BY FISCAL_DAY), FISCAL_DAY) + 1), 2) AS FISCAL_WEEK,
		              DATEPART(WEEKDAY, FISCAL_DAY)     AS FISCAL_WEEKDAY
		         FROM LD.LD_ZFISDAY_SAP) B
		ON A.FISCAL_DAY = B.FISCAL_DAY
		WHEN MATCHED THEN
		  UPDATE SET FISCAL_HALFY = B.FISCAL_HALFY,
		             FISCAL_QUARTER = B.FISCAL_QUARTER,
		             FISCAL_MONTH2 = B.FISCAL_MONTH2,
		             FISCAL_WEEK_NUMBERS = B.FISCAL_WEEK,
		             FISCAL_WEEK2 = CONCAT(FISCAL_YEAR, RIGHT(CONCAT('0', B.FISCAL_WEEK), 2)),
		             FISCAL_WEEKDAY = B.FISCAL_WEEKDAY; 
 
		
    END TRY

    BEGIN CATCH

        SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
               @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

        SET @v_msg='FILE_ID:'+CAST(@FILE_ID AS VARCHAR(20));

        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_DATE_SAP','','EXCEPTION',@v_msg,@errorcode,@errormsg;
        
    END CATCH
 END
    
    EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_DATE_SAP','','MESSAGE','End','','';
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_DATE_SAP','LD','END';

GO
/****** Object:  StoredProcedure [LD].[SP_LD_SKU_STDCOST_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [LD].[SP_LD_SKU_STDCOST_SAP]
  --Load data from staging to loading
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create

AS
	
DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @PROJECT_NAME varchar(50)
    DECLARE @FILE_ID INT

BEGIN
	SET @PROJECT_NAME = 'KAP';
	
  EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_SKU_STDCOST_SAP','LD','START';   
  EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_SKU_STDCOST_SAP','','MESSAGE','Begin','',''; 
  	BEGIN TRY

      TRUNCATE TABLE LD.LD_SKU_STDCOST_SAP;
          
      EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_SKU_STDCOST_SAP','','MESSAGE','Merge','','';
      
      --Update loading table data
			MERGE INTO LD.LD_SKU_STDCOST_SAP T1
				USING (SELECT CASE S.LOCAL_CURRENCY
		 						        WHEN 'HKD' THEN 'USD'
		 						        ELSE S.LOCAL_CURRENCY
		 						      END                                                     AS LOCAL_CURRENCY,
		 						      STUFF(T.BWKEY, 1, PATINDEX ('%[^0]%', T.BWKEY) - 1, '') AS STORE_CODE,
		 						      NULL                                                    AS FISCAL_PERIOD,
		 						      T.PEINH                                                 AS PRICE_UNIT,
		 						      CAST(T.STPRS AS NUMERIC(18,4))                                AS STDCOST_AMT,
		 						      T.MATNR                                                 AS MATERIAL_CODE
		 						 FROM STG.STG_MBEW_Material_SAP T
		 						 LEFT JOIN DW.D_STORE_SAP S
		 						        ON STUFF(T.BWKEY, 1, PATINDEX ('%[^0]%', T.BWKEY) - 1, '') = S.STORE_CODE
		 						WHERE ISNUMERIC(T.STPRS) = 1 ) T2
			ON ( 1 = 2 )
			WHEN NOT MATCHED THEN
			  INSERT ( LOCAL_CURRENCY,
			           STORE_CODE,
			           FISCAL_PERIOD,
			           PRICE_UNIT,
			           STDCOST_AMT,
			           MATERIAL_CODE )
			  VALUES ( T2.LOCAL_CURRENCY,
			           T2.STORE_CODE,
			           T2.FISCAL_PERIOD,
			           T2.PRICE_UNIT,
			           T2.STDCOST_AMT,
			           T2.MATERIAL_CODE ); 
			
			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_SKU_STDCOST_SAP','','MESSAGE','End','','';
			
    END TRY

    BEGIN CATCH

        SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
               @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

        SET @v_msg='FILE_ID:'+CAST(@FILE_ID AS VARCHAR(20));

        EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_SKU_STDCOST_SAP','','EXCEPTION',@v_msg,@errorcode,@errormsg;
    END CATCH
 END
      
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_SKU_STDCOST_SAP','LD','END';


GO
/****** Object:  StoredProcedure [LD].[SP_LD_STORE_SAP]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [LD].[SP_LD_STORE_SAP]
  --Load data from staging to loading
  --Created by   : Daniel
  --Version      : 1.0
  --Modify History: Create
AS

    DECLARE @v_msg varchar(100)
    DECLARE @errorcode varchar(100)
    DECLARE @errormsg varchar(200)
    DECLARE @PROJECT_NAME varchar(50)
    DECLARE @FILE_ID INT

BEGIN

  BEGIN TRY
     SELECT @PROJECT_NAME = 'KAP';
     
     --Begin log
     EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_STORE_SAP','LD','START';
     EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_STORE_SAP', '', 'MESSAGE', 'Begin', '', '';

     TRUNCATE TABLE LD.LD_STORE_SAP
			
			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_STORE_SAP', '', 'MESSAGE', 'Merge', '', '';
			
        --INSERT INTO NEW DATA
        INSERT INTO [LD].[LD_STORE_SAP]
				            ([STORE_CODE],
				             [COUNTRY],
				             [SALES_ORGANIZATION],
				             [SALES_DISTRICT],
				             [CITY],
				             [SITE_ENGLISH_NAME],
				             [SITE_CHINESE_NAME],
				             --[STORE_OPEN_DATE],
				             --[CLOSE_DATE_OF_STORE],
				             --[LOCAL_CURRENCY],
				             [STORE_AREA],
				             [STORE_TYPE_CODE],
				             [REGION_CODE],
				             --[STORE_TYPE_DESC],
				             --[REGION_DESC],
				             [OLD_STORE_CODE],
				             --[AE_CODE],
				             --[SUB_CHANNEL],
				             --[BRAND_ID],
				             --[BRAND_CODE],
				             [COMPANY_CODE],
				             [PURCHASE_ORG],
				             [NEW_CO_FLAG],
				             [COMPANY_DESC],
				             DISTRIBUTION_CHANNEL,
				             STORE_CATEGORY,
				             CUSTOMER_NUMBER)
				SELECT STUFF(A.WERKS, 1, PATINDEX ('%[^0]%', A.WERKS) - 1, '') AS STORE_CODE,
				       A.LAND1                                                 AS COUNTRY,
				       A.VKORG                                                 AS SALES_ORGANIZATION,
				       A.BZIRK                                                 AS SALES_DISTRICT,
				       A.ORT01                                                 AS CITY,
				       A.NAME1                                                 AS SITE_ENGLISH_NAME,
				       A.NAME2                                                 AS SITE_CHINESE_NAME,
				       --(CASE WHEN C33_0RT_LOPDAT = '00000000' THEN NULL ELSE CAST(C33_0RT_LOPDAT AS DATETIME) END ) AS STORE_OPEN_DATE,
				       --(CASE WHEN C32_0RT_LCLDAT = '00000000' THEN NULL ELSE CAST(C32_0RT_LCLDAT AS DATETIME) END ) AS CLOSE_DATE_OF_STORE,
				       --C12_0LOC_CURRCY AS LOCAL_CURRENCY,
				       D.VERFL                                                 AS STORE_AREA,
				       B.PLANT_TYPE                                            AS STORE_TYPE_CODE,
				       A.REGIO                                                 AS REGION_CODE,
				       --K1.SAP_DESC                                             AS STORE_TYPE_DESC,
				       CASE WHEN B.OLD_PLANT IS NULL OR B.OLD_PLANT = '' 
				       			THEN STUFF(A.WERKS, 1, PATINDEX ('%[^0]%', A.WERKS) - 1, '') 
				       			ELSE B.OLD_PLANT 
				       END AS OLD_STORE_CODE,
				       --C37_ZAE AS AE_CODE,
				       --C46_ZTMPSTRID AS SUB_CHANNEL,
				       V.BUKRS                                                 AS COMPANY_CODE,
				       A.EKORG                                                 AS PURCHASE_ORG,
				       CASE
				         WHEN V.BUKRS IN ( '9001', '9201', '9301' ) THEN 1
				         ELSE 0
				       END                                                     AS NEW_CO_FLAG,
				       C.BUTXT                                                 AS COMPANY_DESC,
				       A.VTWEG AS DISTRIBUTION_CHANNEL,
				       A.VLFKZ AS STORE_CATEGORY,
				       STUFF(A.KUNNR, 1, PATINDEX ('%[^0]%', A.KUNNR) - 1, '') AS CUSTOMER_NUMBER
				  FROM STG.STG_T001W_Plant_SAP A
				       LEFT JOIN DW.D_CUSTOMER_SAP B
				              ON STUFF(A.KUNNR, 1, PATINDEX ('%[^0]%', A.KUNNR) - 1, '') = B.CUSTOMER_CODE
				       LEFT JOIN DW.D_T001K_SAP V
				              ON STUFF(A.WERKS, 1, PATINDEX ('%[^0]%', A.WERKS) - 1, '') = V.BWKEY
				       LEFT JOIN DW.D_T001_SAP C
				              ON V.BUKRS = C.BUKRS
				       LEFT JOIN DW.D_WRF1_SAP D
				              ON B.CUSTOMER_CODE = D.LOCNR
				 WHERE STUFF(A.WERKS, 1, PATINDEX ('%[^0]%', A.WERKS) - 1, '') <> ''
				       AND A.VKORG <> '';
      
        UPDATE T
        	 SET STORE_TYPE_DESC = S.SAP_DESC
          FROM LD.LD_STORE_SAP T
      	 INNER JOIN DW.D_KEYDATA_SAP S
      	 		ON S.CODE_TYPE = 'PLANT_TYPE'
      	 	 AND T.STORE_TYPE_CODE = S.SAP_CODE;
      	
	      UPDATE T
        	 SET STORE_CATEGORY_DESC = S.SAP_DESC
          FROM LD.LD_STORE_SAP T
      	 INNER JOIN DW.D_KEYDATA_SAP S
      	 		ON S.CODE_TYPE = 'PLANT_CATEGORY'
      	 	 AND T.STORE_CATEGORY = S.SAP_CODE;
      	 	  	 
      	 UPDATE T
        	 SET REGION_DESC = S.SAP_DESC
          FROM LD.LD_STORE_SAP T
      	 INNER JOIN DW.D_KEYDATA_SAP S
      	 		ON S.CODE_TYPE = 'SAP_REGION'
      	 	 AND T.REGION_CODE = S.SAP_CODE
      	 	 AND T.COUNTRY = S.BRAND;	--Column brand stores country values for SAP_REGION
    
    	EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_STORE_SAP', '', 'MESSAGE', 'End', '', '';
    	  	
    END TRY

    BEGIN CATCH

        SELECT @errorcode = SUBSTRING(CAST(ERROR_NUMBER() AS VARCHAR(100)),0,99),
               @errormsg  = SUBSTRING(ERROR_MESSAGE(),0,199)

        SET @v_msg='FILE_ID:'+CAST(@FILE_ID AS VARCHAR(20));

      	EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_STORE_SAP', '', 'EXCEPTION', @v_msg, @errorcode, @errormsg;
      	
    END CATCH
    
    EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_STORE_SAP','LD','END';
    
 END

GO

/****** Object:  StoredProcedure [LD].[SP_LD_D_ARTICLE_PRICE_SAP]    Script Date: 3/2/2021 9:12:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [LD].[SP_LD_D_ARTICLE_PRICE_SAP] 
AS
DECLARE @v_err_num NUMERIC(18,0);
DECLARE @v_err_msg NVARCHAR(100);
DECLARE @PROJECT_NAME varchar(50)

  BEGIN
  	SET @PROJECT_NAME = 'KAP';
  	
  	BEGIN TRY
  	
  		EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_D_ARTICLE_PRICE_SAP','LD','START';
    	EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_D_ARTICLE_PRICE_SAP', '', 'MESSAGE', 'Begin', '', '';
    	
   		TRUNCATE TABLE LD.D_ARTICLE_PRICE_SAP;
					
 			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_D_ARTICLE_PRICE_SAP','','MESSAGE','INSERT','Retail','';
  		
			INSERT INTO [LD].[D_ARTICLE_PRICE_SAP]
			            ([ARTICLE_NO],
			             [RETAIL_PRICE],
			             [CURRENCY],
			             [VALID_FROM_DATE],
			             [VALID_TO_DATE],
			             [CHANNEL],
			             [SALES_ORG],
			             [WHOLESALE_PRICE])
			SELECT T.MATNR  AS ARTICLE_NO,
			       P.KBETR  AS RETAIL_PRICE,
			       P.KONWA  AS CURRENCY,
			       T.DATAB  AS VALID_FROM_DATE,
			       ISNULL(DATEADD(DAY,-1,LEAD(T.DATAB,1) OVER(PARTITION BY T.MATNR,T.VKORG ORDER BY T.DATAB)),'9999-12-31') AS VALID_TO_DATE,
			       'Retail' AS CHANNEL,
			       T.VKORG  AS SALES_ORG,
			       0        AS WHOLESALE_PRICE
			  FROM STG.STG_A954_SAP T
			       LEFT JOIN STG.STG_KONP_Price_SAP P
			              ON T.KNUMH = P.KNUMH
			 WHERE T.KSCHL = 'VKP0'
			       AND T.VTWEG = '30'
			 ORDER BY T.MATNR, T.DATAB;  
		
			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_D_ARTICLE_PRICE_SAP','','MESSAGE','INSERT','Wholesale','';
			
			--Wholesale price from A951
			INSERT INTO [LD].[D_ARTICLE_PRICE_SAP]
			            ([ARTICLE_NO],
			             [RETAIL_PRICE],
			             [CURRENCY],
			             [VALID_FROM_DATE],
			             [VALID_TO_DATE],
			             [CHANNEL],
			             [SALES_ORG],
			             [WHOLESALE_PRICE])
			SELECT T.MATNR  AS ARTICLE_NO,
			       0  AS RETAIL_PRICE,
			       P.KONWA  AS CURRENCY,
			       T.DATAB  AS VALID_FROM_DATE,
			       ISNULL(DATEADD(DAY,-1,LEAD(T.DATAB,1) OVER(PARTITION BY T.MATNR,T.VKORG ORDER BY T.DATAB)),'9999-12-31') AS VALID_TO_DATE,
			       'Wholesale' AS CHANNEL,
			       T.VKORG  AS SALES_ORG,
			       P.KBETR  AS WHOLESALE_PRICE
			  FROM STG.STG_A951_Tax_SAP T
			       LEFT JOIN STG.STG_KONP_Price_SAP P
			              ON T.KNUMH = P.KNUMH
			 WHERE T.KSCHL = 'ZPR0'
			       AND T.VTWEG = '20'
			 ORDER BY T.MATNR, T.DATAB;
			
			--Wholesale price from A902
			INSERT INTO [LD].[D_ARTICLE_PRICE_SAP]
			            ([ARTICLE_NO],
			             [RETAIL_PRICE],
			             [CURRENCY],
			             [VALID_FROM_DATE],
			             [VALID_TO_DATE],
			             [CHANNEL],
			             [SALES_ORG],
			             [WHOLESALE_PRICE])
			SELECT T.MATNR  AS ARTICLE_NO,
			       0  AS RETAIL_PRICE,
			       P.KONWA  AS CURRENCY,
			       T.DATAB  AS VALID_FROM_DATE,
			       ISNULL(DATEADD(DAY,-1,LEAD(T.DATAB,1) OVER(PARTITION BY T.MATNR,T.VKORG ORDER BY T.DATAB)),'9999-12-31') AS VALID_TO_DATE,
			       'Wholesale' AS CHANNEL,
			       T.VKORG  AS SALES_ORG,
			       P.KBETR  AS WHOLESALE_PRICE
			  FROM STG.STG_A902_Price_SAP T
			       LEFT JOIN STG.STG_KONP_Price_SAP P
			              ON T.KNUMH = P.KNUMH
			 WHERE T.KSCHL = 'ZPR0'
			       AND T.VTWEG = '20'
			       AND NOT EXISTS(SELECT 1 FROM [LD].[D_ARTICLE_PRICE_SAP] S 
			       								 WHERE S.CHANNEL = 'Wholesale' 
			       								 	 AND T.MATNR = S.ARTICLE_NO 
			       								 	 AND T.VKORG = S.SALES_ORG)
			 ORDER BY T.MATNR, T.DATAB;
			  
			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME, 'SP_LD_D_ARTICLE_PRICE_SAP', '', 'MESSAGE', 'End', '', '';
			 
		END TRY
		
		BEGIN CATCH
			SET @v_err_num = ERROR_NUMBER();
			SET @v_err_msg = SUBSTRING(ERROR_MESSAGE(), 1, 100);

			EXEC DW.SP_SYS_ETL_LOG @PROJECT_NAME,'SP_LD_D_ARTICLE_PRICE_SAP','','EXCEPTION',@v_err_num,@v_err_msg,'';

		END CATCH 
	EXEC DW.SP_SYS_ETL_STATUS @PROJECT_NAME,'SP_LD_D_ARTICLE_PRICE_SAP','LD','END';
    
	END


/****** Object:  StoredProcedure [DW].[SP_DW_ETL_SAP_MAIN]    Script Date: 2/23/2021 3:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [DW].[SP_DW_ETL_SAP_MAIN](@VARNAME NVARCHAR(20))
AS

BEGIN
	-- ##############################################################
	-- # Process Chain to call all the procedure of SAP SLT DATA
	-- ##############################################################
	
IF @VARNAME='D'	
BEGIN
	EXEC LD.SP_LD_DATE_SAP;
	EXEC DW.SP_D_DATE_SAP;
	EXEC DW.SP_D_ARTICLE_DESC_SAP;
	EXEC DW.SP_D_FSHSEASONSMAT_SAP;
	EXEC DW.SP_D_KLAH_SAP;
	EXEC DW.SP_D_WRFMATGRPSKU_SAP;
	EXEC DW.SP_D_WRF_MATGRP_STRCT_SAP;
	EXEC DW.SP_D_SWOR_SAP;
	EXEC LD.SP_LD_ARTICLE_SAP;
	EXEC DW.SP_D_ARTICLE_SAP;
	EXEC DW.SP_D_EXCHANGE_RATE_SAP;
	EXEC DW.SP_D_CUSTOMER_SAP;
	EXEC DW.SP_D_T001K_SAP;
	EXEC DW.SP_D_T001_SAP;
	EXEC DW.SP_D_WRF1_SAP;
	EXEC LD.SP_LD_STORE_SAP;
	EXEC DW.SP_D_STORE_SAP;
	EXEC LD.SP_LD_D_ARTICLE_PRICE_SAP;
	EXEC DW.SP_D_ARTICLE_PRICE_SAP;
	EXEC LD.SP_LD_SKU_STDCOST_SAP;
	EXEC DW.SP_D_SKU_STDCOST_SAP;
	EXEC DW.SP_D_INVENTORY_CLASS_SAP;
	EXEC DW.SP_D_PRODUCT_COST_SAP;
END
	
ELSE IF @VARNAME='F'
BEGIN

	EXEC DW.SP_F_EKKO_SAP;
	EXEC DW.SP_F_EKPO_SAP;
	EXEC DW.SP_F_EKES_SAP;	
	EXEC DW.SP_F_STOCK_SAP;	
END
	
END;
GO



