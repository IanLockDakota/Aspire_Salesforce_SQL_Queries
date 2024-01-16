/*
Name: Notes

ASPIRE SQLS Table Dependencies:
    - Contract
    - Entity
    - Comment
    - GenericField
    - cdataGenericValue

Salesforce Backups Table Dependencies:
    - Notes_ASPIRE__c_upsert

SF Object Dependencies:
    - Notes_ASPIRE__c

Last change: 11/30/2023

Other Notes:
    - START and END parameters to set timeframe of data to be pulled
    - Missing CommentOID
*/

-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(DAY, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

MERGE INTO Notes_ASPIRE__c_upsert AS Target
USING (SELECT
NULL AS ID,
d.oid AS CommentOID__c,
OppIDTable.opportunityID AS Opportunity__c,
d.ContractOid AS ContractOID__c,
d.EntityOid AS EntityOID__c,
d.ref_type AS Ref_Type__c,
d.message_type AS Message_Type__c,
d.text AS Text__c,
d.create_datetime AS Create_DateTime__c,
d.orig_user_name AS Orig_User_Name__c,
d.LastChangeOperator AS LastChangeOperator__c,
d.LastChangeDateTime AS LastChangeDateTime__c

FROM
    /* CNTRCT COMMENTS */
    (SELECT 
        con.ContractOid,
        con.ContractId,
        con.EntityOid,
        Com.ref_oid,
        Com.ref_type,
        Com.comttype_oid,
        Com.oid,
        Com.message_type,
        Com.text, 
        Com.create_datetime, 
        Com.orig_user_name, 
        Com.LastChangeOperator, 
        Com.LastChangeDateTime
    FROM
        [ASPIRESQL].[AspireDakota].[dbo].[Contract] Con LEFT OUTER JOIN
        [ASPIRESQL].[AspireDakota].[dbo].[Entity] Ent ON Con.EntityOid = Ent.oid RIGHT OUTER JOIN
        [ASPIRESQL].[AspireDakota].[dbo].[Comment] Com ON Con.ContractOid = Com.ref_oid
    WHERE
    	(com.text IS NOT NULL)
	    AND (com.ref_type <> 'ACCT')

    UNION ALL
    
    /* ACCT COMMENTS FOR ENTITIES WITH ONE DEAL */

    SELECT
    ContractOid,
    ContractId,
    EntityOid, 
    ref_oid, 
    ref_type, 
    comttype_oid, 
    oid, 
    message_type, 
    text, 
    create_datetime, 
    orig_user_name, 
    LastChangeOperator, 
    LastChangeDateTime
	FROM (
		SELECT
			CASE
				WHEN Comment_1.ref_type = 'ACCT' AND Comment_1.create_datetime BETWEEN conCheck.StartDate AND ISNULL(conCheck.TerminationDATE, GETDATE()) THEN concheck.ContractOid
				ELSE NULL
			END AS ContractOid,
			CASE
				WHEN Comment_1.ref_type = 'ACCT' AND Comment_1.create_datetime BETWEEN conCheck.StartDate AND ISNULL(conCheck.TerminationDATE, GETDATE()) THEN concheck.contractID
				ELSE NULL
			END AS ContractId,
			Entity_1.oid AS EntityOid, 
			Comment_1.ref_oid, 
			Comment_1.ref_type, 
			Comment_1.comttype_oid, 
			Comment_1.oid, 
			Comment_1.message_type, 
			Comment_1.text, 
			Comment_1.create_datetime, 
			Comment_1.orig_user_name, 
			Comment_1.LastChangeOperator, 
			Comment_1.LastChangeDateTime
		FROM
        [ASPIRESQL].[AspireDakota].[dbo].[Entity] AS Entity_1
        LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Comment] AS Comment_1 ON Entity_1.oid = Comment_1.ref_oid 
        LEFT OUTER JOIN (
            SELECT
                co1.contractID,
                co1.ContractOid,
                e1.oid,
                ct.StartDate,
                co1.TerminationDate
            FROM
                [ASPIRESQL].[AspireDakota].[dbo].[Entity] e1
                LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] co1 ON e1.oid = co1.EntityOid
                INNER JOIN [ASPIRESQL].[AspireDakota].[dbo].[ContractTerm] ct ON co1.ContractOid = ct.ContractOid
        ) AS conCheck ON entity_1.oid = conCheck.oid
        WHERE
            (Comment_1.text IS NOT NULL)
            AND (Comment_1.ref_type = 'ACCT')
            AND (Entity_1.oid NOT IN ('48265', '50608', '51096', '43996', '47854', '46174', '51258', '53653', '55495', '60900', '61152', '60855', '56215', '56830', '63543', '65735', '52109', '50611', '50467', '50635', '47284', '47356', '48181', '48316', '44691', '43210', '42793', '37223', '39212', '39331', '40787', '77535', '76223', '71847', '72403', '72933', '40093', '40817', '40844', '39969', '40076', '40485', '39235', '39211', '39101', '39132', '39013', '37304', '37463', '36788', '37649', '37733', '38149', '38335', '38538', '42552', '41001', '41265', '41409', '41651', '43564', '45335', '48022', '48500', '48701', '48673', '48873', '49108', '49141', '49163', '49420', '49725', '49817', '49889', '49651', '49719', '49969', '47368', '46810', '46437', '46596', '45668', '50641', '50837', '50850', '51308', '51459', '51766', '52181', '52278', '52690', '53783', '53793', '53192', '52843', '65830', '64543', '65549', '65593', '65644', '63524', '62359', '63714', '64161', '64434', '67511', '67976', '70577', '70507', '57541', '55516', '56599', '56725', '53952', '54185', '54581', '54984', '60923', '61010', '60331', '61433', '61713', '58765', '58686', '58563', '58356', '58194', '58660', '58836', '58917', '59017', '58043', '58132', '57953', '57771', '58177', '58182', '58213', '58267', '58394', '58496', '58893', '49966', '58762', '59012', '59125', '59139', '59163', '59220', '59308', '59431', '59374', '59377', '59207', '59273', '59288', '59294', '59117', '59561', '59572', '59667', '59712', '59747', '59833', '59859', '59938', '59901', '59904', '60047', '60063', '60103', '62116', '62129', '62148', '62170', '62274', '62398', '61812', '61671', '62028', '62066', '61445', '61458', '61356', '61394', '60999', '61142', '61222', '61263', '61268', '61482', '61617', '61730', '60417', '60649', '60201', '60446', '59739', '60087', '60813', '60903', '60861', '60679', '60719', '60747', '60786', '60788', '54977', '54980', '54723', '54952', '54955', '54520', '54796', '55047', '54666', '54742', '54840', '54505', '54545', '54597', '54234', '54197', '54483', '53800', '53963', '54081', '54145', '54087', '54308', '55217', '55473', '55176', '55004', '54993', '55036', '55537', '55540', '55698', '55876', '55225', '56349', '56799', '56895', '56271', '56299', '55800', '56320', '56541', '56544', '55505', '55511', '55983', '55987', '55810', '56030', '56105', '55532', '55690', '56150', '56220', '56166', '56169', '56375', '57482', '57633', '57601', '57725', '57784', '57440', '57478', '57717', '57765', '57851', '57885', '57985', '56854', '57316', '57273', '56331', '56824', '57394', '57402', '57445', '57019', '57130', '69944', '70955', '71014', '71104', '71443', '69329', '65567', '67994', '69370', '69938', '69983', '70799', '69125', '69179', '69244', '69600', '69658', '69817', '70033', '67724', '67674', '67677', '67696', '68293', '68372', '68570', '68831', '68503', '68978', '69040', '68796', '69092', '69376', '67394', '67417', '67540', '67086', '67176', '67234', '67735', '68002', '68173', '64155', '64183', '64370', '64211', '64281', '64666', '64034', '64063', '63551', '63757', '63378', '63280', '63517', '63302', '63337', '63383', '63079', '63021', '63228', '62485', '62368', '61130', '62166', '62681', '62692', '62757', '62908', '65779', '65577', '65623', '64892', '64898', '64636', '64640', '64970', '65325', '65418', '64478', '64441', '64458', '64496', '64563', '64601', '64904', '65069', '65197', '66046', '65983', '65847', '65918', '66067', '66383', '66506', '66582', '66891', '66780', '66857', '66484', '67065', '53185', '53330', '53149', '53172', '53268', '53195', '53199', '52864', '53116', '53362', '53344', '53461', '53475', '53560', '53608', '53554', '53776', '53905', '53505', '53518', '53540', '53549', '53765', '53968', '54020', '53809', '52675', '52820', '52849', '53047', '52904', '52567', '52428', '52553', '52559', '52647', '52708', '52766', '51497', '51864', '52091', '52095', '52244', '52118', '52112', '51871', '52379', '52395', '52397', '52331', '52441', '51818', '51524', '51548', '51710', '51510', '51586', '51878', '51916', '51969', '51997', '52035', '51400', '51392', '51449', '51245', '51374', '51380', '51421', '51601', '51227', '51270', '51287', '51165', '51051', '51071', '50861', '51016', '50884', '50827', '50602', '50127', '50678', '50180', '50082', '50043', '50037', '50077', '50136', '50147', '50476', '50506', '43990', '45387', '45393', '45803', '45579', '45703', '45812', '45815', '45865', '45965', '46045', '46085', '46087', '46625', '46654', '46672', '46687', '46418', '46426', '46463', '46452', '46512', '46519', '46545', '46036', '46374', '46385', '46018', '46074', '46147', '46199', '47019', '46737', '46762', '46835', '46537', '47276', '47324', '47203', '47237', '47056', '47133', '47135', '47384', '47313', '47301', '47466', '47604', '47713', '47424', '47413', '47533', '47562', '47813', '49414', '49652', '49940', '49663', '49459', '49562', '49577', '49589', '49434', '49438', '49227', '49513', '49254', '49131', '49206', '49209', '49215', '49036', '43563', '49103', '48967', '49040', '48680', '48760', '48784', '48883', '48824', '48930', '48009', '48662', '48644', '48558', '48422', '48474', '48516', '47999', '48075', '48129', '47400', '47551', '47847', '47897', '47905', '48221', '48377', '48354', '48411', '48096', '44971', '45364', '45009', '45098', '45400', '45404', '45407', '45431', '45496', '44985', '44986', '45043', '45179', '43903', '44107', '44573', '44744', '44626', '44911', '43197', '43328', '43597', '42166', '42544', '43156', '43168', '42927', '43182', '43512', '43370', '43676', '43677', '43629', '43798', '44203', '41656', '41660', '41462', '41788', '41397', '41496', '39968', '40843', '41786', '41877', '41514', '41161', '41200', '40914', '40942', '41055', '42503', '42750', '43046', '42930', '43018', '43134', '41903', '42003', '41992', '42060', '42107', '42171', '42172', '42278', '42287', '42361', '42066', '42067', '42399', '42422', '42153', '42466', '38350', '37746', '37753', '38151', '38470', '38514', '38628', '38703', '38820', '37870', '37908', '36476', '37271', '37527', '37757', '38011', '38089', '38358', '36747', '36899', '36963', '36484', '36572', '37285', '37491', '37529', '37142', '37068', '38924', '38985', '39000', '38765', '38766', '38767', '38804', '38805', '38942', '39096', '39110', '39059', '39130', '39200', '39123', '39284', '39370', '39400', '39434', '39524', '39628', '40098', '40268', '40350', '40388', '39389', '40227', '40301', '40302', '39462', '40818', '40714', '40825', '40335', '40693', '40374', '40537', '40568', '40634', '40719', '72437', '72597', '72646', '72549', '72528', '72724', '72729', '73201', '72756', '72884', '72748', '72894', '72900', '73502', '71978', '72197', '72224', '72268', '71994', '71889', '71905', '72043', '72088', '70492', '71828', '71920', '71693', '71727', '71761', '71199', '70545', '71154', '71415', '71655', '73587', '73780', '73962', '73721', '73685', '73574', '73885', '73891', '74225', '74316', '74434', '74551', '74738', '73904', '74190', '74212', '74217', '74901', '74939', '75145', '75298', '75491', '75685', '76323', '75595', '76158', '75885', '76021', '76673', '77386', '77159', '75864', '77519', '77800', '76458', '76567', '76388', '75124', '75478', '77137', '77198', '78014', '77774', '77882', '77923', '78321', '78584', '78787', '78503', '78548', '79031', '79087', '79217', '79877', '80516', '79521', '80427', '79488', '80949', '80993', '81128', '81362', '81635', '81914', '82035', '82479', '82899', '82902', '82266', '82193', '83189', '83282', '83475', '83671', '83842', '83948', '78001', '82025', '82251', '83398', '84085', '84177', '84851', '84523', '85736', '86099', '85584', '83431', '82466', '82188'))
        ) AS Subquery
        WHERE
            ContractID IS NOT NULL
            
    UNION ALL

    /* ACCT COMMENTS FOR ENTITIES WITH MULTIPLE DEALS */

    SELECT
    MIN(ContractOid) AS ContractOid,
    MIN(ContractId) AS ContractId,
    EntityOid, 
    ref_oid, 
    ref_type, 
    comttype_oid, 
    oid, 
    message_type, 
    CAST(MIN(CAST(text AS VARCHAR(MAX))) AS TEXT) AS text, 
    create_datetime, 
    orig_user_name, 
    LastChangeOperator, 
    LastChangeDateTime
FROM (
    SELECT
        CASE
            WHEN Comment_1.ref_type = 'ACCT' AND Comment_1.create_datetime BETWEEN conCheck.StartDate AND ISNULL(conCheck.TerminationDATE, GETDATE()) THEN concheck.ContractOid
            ELSE NULL
        END AS ContractOid,
        CASE
            WHEN Comment_1.ref_type = 'ACCT' AND Comment_1.create_datetime BETWEEN conCheck.StartDate AND ISNULL(conCheck.TerminationDATE, GETDATE()) THEN concheck.contractID
            ELSE NULL
        END AS ContractId,
        Entity_1.oid AS EntityOid, 
        Comment_1.ref_oid, 
        Comment_1.ref_type, 
        Comment_1.comttype_oid, 
        Comment_1.oid, 
        Comment_1.message_type, 
        Comment_1.text, 
        Comment_1.create_datetime, 
        Comment_1.orig_user_name, 
        Comment_1.LastChangeOperator, 
        Comment_1.LastChangeDateTime
    FROM
        [ASPIRESQL].[AspireDakota].[dbo].[Entity] AS Entity_1
        LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Comment] AS Comment_1 ON Entity_1.oid = Comment_1.ref_oid 
        LEFT OUTER JOIN (
            SELECT
                co1.contractID,
                co1.ContractOid,
                e1.oid,
                ct.StartDate,
                co1.TerminationDate
            FROM
                [ASPIRESQL].[AspireDakota].[dbo].[Entity] e1
                LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] co1 ON e1.oid = co1.EntityOid
                INNER JOIN [ASPIRESQL].[AspireDakota].[dbo].[ContractTerm] ct ON co1.ContractOid = ct.ContractOid
        ) AS conCheck ON entity_1.oid = conCheck.oid
    WHERE
        (Comment_1.text IS NOT NULL)
        AND (Comment_1.ref_type = 'ACCT')
        AND (Entity_1.oid IN ('48265', '50608', '51096', '43996', '47854', '46174', '51258', '53653', '55495', '60900', '61152', '60855', '56215', '56830', '63543', '65735', '52109', '50611', '50467', '50635', '47284', '47356', '48181', '48316', '44691', '43210', '42793', '37223', '39212', '39331', '40787', '77535', '76223', '71847', '72403', '72933', '40093', '40817', '40844', '39969', '40076', '40485', '39235', '39211', '39101', '39132', '39013', '37304', '37463', '36788', '37649', '37733', '38149', '38335', '38538', '42552', '41001', '41265', '41409', '41651', '43564', '45335', '48022', '48500', '48701', '48673', '48873', '49108', '49141', '49163', '49420', '49725', '49817', '49889', '49651', '49719', '49969', '47368', '46810', '46437', '46596', '45668', '50641', '50837', '50850', '51308', '51459', '51766', '52181', '52278', '52690', '53783', '53793', '53192', '52843', '65830', '64543', '65549', '65593', '65644', '63524', '62359', '63714', '64161', '64434', '67511', '67976', '70577', '70507', '57541', '55516', '56599', '56725', '53952', '54185', '54581', '54984', '60923', '61010', '60331', '61433', '61713', '58765', '58686', '58563', '58356', '58194', '58660', '58836', '58917', '59017', '58043', '58132', '57953', '57771', '58177', '58182', '58213', '58267', '58394', '58496', '58893', '49966', '58762', '59012', '59125', '59139', '59163', '59220', '59308', '59431', '59374', '59377', '59207', '59273', '59288', '59294', '59117', '59561', '59572', '59667', '59712', '59747', '59833', '59859', '59938', '59901', '59904', '60047', '60063', '60103', '62116', '62129', '62148', '62170', '62274', '62398', '61812', '61671', '62028', '62066', '61445', '61458', '61356', '61394', '60999', '61142', '61222', '61263', '61268', '61482', '61617', '61730', '60417', '60649', '60201', '60446', '59739', '60087', '60813', '60903', '60861', '60679', '60719', '60747', '60786', '60788', '54977', '54980', '54723', '54952', '54955', '54520', '54796', '55047', '54666', '54742', '54840', '54505', '54545', '54597', '54234', '54197', '54483', '53800', '53963', '54081', '54145', '54087', '54308', '55217', '55473', '55176', '55004', '54993', '55036', '55537', '55540', '55698', '55876', '55225', '56349', '56799', '56895', '56271', '56299', '55800', '56320', '56541', '56544', '55505', '55511', '55983', '55987', '55810', '56030', '56105', '55532', '55690', '56150', '56220', '56166', '56169', '56375', '57482', '57633', '57601', '57725', '57784', '57440', '57478', '57717', '57765', '57851', '57885', '57985', '56854', '57316', '57273', '56331', '56824', '57394', '57402', '57445', '57019', '57130', '69944', '70955', '71014', '71104', '71443', '69329', '65567', '67994', '69370', '69938', '69983', '70799', '69125', '69179', '69244', '69600', '69658', '69817', '70033', '67724', '67674', '67677', '67696', '68293', '68372', '68570', '68831', '68503', '68978', '69040', '68796', '69092', '69376', '67394', '67417', '67540', '67086', '67176', '67234', '67735', '68002', '68173', '64155', '64183', '64370', '64211', '64281', '64666', '64034', '64063', '63551', '63757', '63378', '63280', '63517', '63302', '63337', '63383', '63079', '63021', '63228', '62485', '62368', '61130', '62166', '62681', '62692', '62757', '62908', '65779', '65577', '65623', '64892', '64898', '64636', '64640', '64970', '65325', '65418', '64478', '64441', '64458', '64496', '64563', '64601', '64904', '65069', '65197', '66046', '65983', '65847', '65918', '66067', '66383', '66506', '66582', '66891', '66780', '66857', '66484', '67065', '53185', '53330', '53149', '53172', '53268', '53195', '53199', '52864', '53116', '53362', '53344', '53461', '53475', '53560', '53608', '53554', '53776', '53905', '53505', '53518', '53540', '53549', '53765', '53968', '54020', '53809', '52675', '52820', '52849', '53047', '52904', '52567', '52428', '52553', '52559', '52647', '52708', '52766', '51497', '51864', '52091', '52095', '52244', '52118', '52112', '51871', '52379', '52395', '52397', '52331', '52441', '51818', '51524', '51548', '51710', '51510', '51586', '51878', '51916', '51969', '51997', '52035', '51400', '51392', '51449', '51245', '51374', '51380', '51421', '51601', '51227', '51270', '51287', '51165', '51051', '51071', '50861', '51016', '50884', '50827', '50602', '50127', '50678', '50180', '50082', '50043', '50037', '50077', '50136', '50147', '50476', '50506', '43990', '45387', '45393', '45803', '45579', '45703', '45812', '45815', '45865', '45965', '46045', '46085', '46087', '46625', '46654', '46672', '46687', '46418', '46426', '46463', '46452', '46512', '46519', '46545', '46036', '46374', '46385', '46018', '46074', '46147', '46199', '47019', '46737', '46762', '46835', '46537', '47276', '47324', '47203', '47237', '47056', '47133', '47135', '47384', '47313', '47301', '47466', '47604', '47713', '47424', '47413', '47533', '47562', '47813', '49414', '49652', '49940', '49663', '49459', '49562', '49577', '49589', '49434', '49438', '49227', '49513', '49254', '49131', '49206', '49209', '49215', '49036', '43563', '49103', '48967', '49040', '48680', '48760', '48784', '48883', '48824', '48930', '48009', '48662', '48644', '48558', '48422', '48474', '48516', '47999', '48075', '48129', '47400', '47551', '47847', '47897', '47905', '48221', '48377', '48354', '48411', '48096', '44971', '45364', '45009', '45098', '45400', '45404', '45407', '45431', '45496', '44985', '44986', '45043', '45179', '43903', '44107', '44573', '44744', '44626', '44911', '43197', '43328', '43597', '42166', '42544', '43156', '43168', '42927', '43182', '43512', '43370', '43676', '43677', '43629', '43798', '44203', '41656', '41660', '41462', '41788', '41397', '41496', '39968', '40843', '41786', '41877', '41514', '41161', '41200', '40914', '40942', '41055', '42503', '42750', '43046', '42930', '43018', '43134', '41903', '42003', '41992', '42060', '42107', '42171', '42172', '42278', '42287', '42361', '42066', '42067', '42399', '42422', '42153', '42466', '38350', '37746', '37753', '38151', '38470', '38514', '38628', '38703', '38820', '37870', '37908', '36476', '37271', '37527', '37757', '38011', '38089', '38358', '36747', '36899', '36963', '36484', '36572', '37285', '37491', '37529', '37142', '37068', '38924', '38985', '39000', '38765', '38766', '38767', '38804', '38805', '38942', '39096', '39110', '39059', '39130', '39200', '39123', '39284', '39370', '39400', '39434', '39524', '39628', '40098', '40268', '40350', '40388', '39389', '40227', '40301', '40302', '39462', '40818', '40714', '40825', '40335', '40693', '40374', '40537', '40568', '40634', '40719', '72437', '72597', '72646', '72549', '72528', '72724', '72729', '73201', '72756', '72884', '72748', '72894', '72900', '73502', '71978', '72197', '72224', '72268', '71994', '71889', '71905', '72043', '72088', '70492', '71828', '71920', '71693', '71727', '71761', '71199', '70545', '71154', '71415', '71655', '73587', '73780', '73962', '73721', '73685', '73574', '73885', '73891', '74225', '74316', '74434', '74551', '74738', '73904', '74190', '74212', '74217', '74901', '74939', '75145', '75298', '75491', '75685', '76323', '75595', '76158', '75885', '76021', '76673', '77386', '77159', '75864', '77519', '77800', '76458', '76567', '76388', '75124', '75478', '77137', '77198', '78014', '77774', '77882', '77923', '78321', '78584', '78787', '78503', '78548', '79031', '79087', '79217', '79877', '80516', '79521', '80427', '79488', '80949', '80993', '81128', '81362', '81635', '81914', '82035', '82479', '82899', '82902', '82266', '82193', '83189', '83282', '83475', '83671', '83842', '83948', '78001', '82025', '82251', '83398', '84085', '84177', '84851', '84523', '85736', '86099', '85584', '83431', '82466', '82188'))
) AS Subquery
WHERE
    ContractID IS NOT NULL
GROUP BY
	EntityOid, 
    ref_oid, 
    ref_type, 
    comttype_oid, 
    oid, 
    message_type, 
    create_datetime, 
    orig_user_name, 
    LastChangeOperator, 
    LastChangeDateTime) as d LEFT OUTER JOIN

    (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
    FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
    LEFT OUTER JOIN [ASPIRESQL].[ASPIREDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid
    LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
    WHERE GF.oid = 23
    GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIDTable ON d.ContractOid = OppIDTable.ContractOID
    WHERE (d.LastChangeDateTime BETWEEN @start and @end)) AS Source
    ON Target.CommentOID__c = Source.CommentOID__c -- Add any additional conditions for matching records

WHEN MATCHED THEN
    UPDATE SET
        Target.EntityOID__c = Source.EntityOID__c,
        Target.Ref_Type__c = Source.Ref_Type__c,
        Target.Message_Type__c = Source.Message_Type__c,
        Target.Text__c = Source.Text__c,
        Target.Create_DateTime__c = Source.Create_DateTime__c,
        Target.Orig_User_Name__c = Source.Orig_User_Name__c,
        Target.LastChangeOperator__c = Source.LastChangeOperator__c,
        Target.LastChangeDateTime__c = Source.LastChangeDateTime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        CommentOID__c,
        EntityOID__c,
        Ref_Type__c,
        Message_Type__c,
        Text__c,
        Create_DateTime__c,
        Orig_User_Name__c,
        LastChangeOperator__c,
        LastChangeDateTime__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c, 
        Source.CommentOID__c,
        Source.EntityOID__c,
        Source.Ref_Type__c,
        Source.Message_Type__c,
        Source.Text__c,
        Source.Create_DateTime__c,
        Source.Orig_User_Name__c,
        Source.LastChangeOperator__c,
        Source.LastChangeDateTime__c
    );