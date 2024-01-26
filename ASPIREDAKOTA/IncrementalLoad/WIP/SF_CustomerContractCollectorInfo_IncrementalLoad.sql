-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(HOUR, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

MERGE INTO Customer_And_Related_Collections__c_upsert AS Target
USING (SELECT
	NULL AS ID,
	CONCAT(c.contractOID, chen.entt_oid, LEFT(r.descr,1)) AS UniqueID__C,
	c.contractOID AS ContractOID__C,
	OppIDTable.OpportunityID AS Opportunity__c,
	chen.entt_oid AS EntityOID__C, 
	r.descr AS RoleType__c,
	e.name AS Name__C,
	e.legal_name AS LegalName__c,
	e.alt_name AS AltName__c,
	e.email_addr AS EmailAddress__c,
	cbtlloc.FullAddress AS BillToLocation__c,
	ctxloc.FullAddress AS TaxLocation__c,
	celoc.FullAddress AS CEBillToLocation__c,
	CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE e.CollectorOid END AS CollectorOID__c,
    CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE collector.name END AS CollectorName__c,
    CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE e.PermanentCollectionAssignmentFlag END AS PermanentCollectionAssignmentFlag__c,
	CASE
        WHEN e.LastChangeDateTime >= cbtlloc.LastChangeDateTime AND e.LastChangeDateTime >= celoc.LastChangeDateTime THEN e.LastChangeDateTime
        WHEN cbtlloc.LastChangeDateTime >= e.LastChangeDateTime AND cbtlloc.LastChangeDateTime >= celoc.LastChangeDateTime THEN cbtlloc.LastChangeDateTime
        ELSE celoc.LastChangeDateTime
    END AS LastChangeDateTime__c,
	CASE
        WHEN e.LastChangeDateTime >= cbtlloc.LastChangeDateTime AND e.LastChangeDateTime >= celoc.LastChangeDateTime THEN e.LastChangeOperator
        WHEN cbtlloc.LastChangeDateTime >= e.LastChangeDateTime AND cbtlloc.LastChangeDateTime >= celoc.LastChangeDateTime THEN cbtlloc.LastChangeOperator
        ELSE celoc.LastChangeOperator
    END AS LastChangeOperator__c
FROM
	[ASPIRESQL].[AspireDakota].[dbo].[Contract] c
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[ChildEntity] chen ON chen.ref_oid = c.contractOID
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[role] r ON r.oid = chen.role_oid
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Entity] e ON chen.entt_oid = e.oid
	LEFT OUTER JOIN
		(SELECT DISTINCT
			e.CollectorOid,
			e2.name
		FROM 
			[ASPIRESQL].[AspireDakota].[dbo].[Entity] e
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Entity] e2 ON e.collectorOID = e2.oid
		WHERE
			e2.name IS NOT NULL) AS collector ON e.collectorOID = collector.CollectorOid
	LEFT OUTER JOIN
		(SELECT 
			c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
		FROM 
			[ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid 
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
		WHERE 
			GF.oid = 23
		GROUP BY 
			c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppID ON c.contractOID = OppID.ContractOid
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			c.BillToLocationOid,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress,
            c.LastChangeDateTime,
			c.LastChangeOperator
		FROM
			[ASPIRESQL].[AspireDakota].[dbo].[contract] c
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[contractEquipment] ce ON c.contractOID = ce.ContractOid
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Location] loc ON c.BillToLocationOid = loc.oid) AS cbtlloc ON c.contractOID = cbtlloc.contractOID
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			c.TaxLocationOid,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress
		FROM
			[ASPIRESQL].[AspireDakota].[dbo].[contract] c
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Location] loc ON c.TaxLocationOid = loc.oid) AS ctxloc ON c.contractOID = ctxloc.contractOID
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			ce.BilltoLocationOid AS ceBillToLocationOID,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress,
            ce.LastChangeDateTime,
			ce.LastChangeOperator
		FROM
			[ASPIRESQL].[AspireDakota].[dbo].[contract] c
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[contractEquipment] ce ON c.contractOID = ce.ContractOid
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Location] loc ON ce.BilltoLocationOid = loc.oid
        WHERE
			ce.IsPrimaryforPricing = 1) AS celoc ON c.contractOID = celoc.contractOID
	LEFT OUTER JOIN
		(SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
    	FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
   		LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
   		[ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
   		WHERE GF.oid = 23
    	GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIDTable ON c.contractOID = OppIDTable.contractOID
WHERE
	(chen.entt_OID <> 1) AND (r.descr NOT IN ('Collector', 'Broker', 'Contract Manager')) AND ((e.LastChangeDateTime BETWEEN @start and @end) OR (cbtlloc.LastChangeDateTime BETWEEN @start and @end) OR (celoc.LastChangeDateTime BETWEEN @start and @end))) AS Source
ON Target.UniqueID__C = Source.UniqueID__C

WHEN MATCHED THEN
    UPDATE SET
		Target.EntityOID__C = Source.EntityOID__C,
		Target.Opportunity__c = Source.Opportunity__c,
		Target.RoleType__c = Source.RoleType__c,
		Target.Name__C = Source.Name__C,
		Target.LegalName__c = Source.LegalName__c,
		Target.AltName__c = Source.AltName__c,
		Target.BillToLocation__c = Source.BillToLocation__c,
		Target.TaxLocation__c = Source.TaxLocation__c,
		Target.CEBillToLocation__c = Source.CEBillToLocation__c,
		Target.EmailAddress__c = Source.EmailAddress__c,
		Target.CollectorOID__c = Source.CollectorOID__c,
		Target.CollectorName__c = Source.CollectorName__c,
		Target.PermanentCollectionAssignmentFlag__c = Source.PermanentCollectionAssignmentFlag__c,
		Target.LastChangeOperator__c = Source.LastChangeOperator__c,
		Target.LastChangeDateTime__c = Source.LastChangeDateTime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID, 
		UniqueID__C, 
		Opportunity__c, 
		EntityOID__C , 
		RoleType__c, 
		Name__C, 
		LegalName__c, 
		AltName__c, 
		EmailAddress__c, 
		BillToLocation__c, 
		TaxLocation__c, 
		CEBillToLocation__c, 
		CollectorOID__c, 
		CollectorName__c, 
		PermanentCollectionAssignmentFlag__c, 
		LastChangeDateTime__c, 
		LastChangeOperator__c

    ) VALUES (
        Source.ID, 
		Source.UniqueID__C, 
		Source.Opportunity__c, 
		Source.EntityOID__C , 
		Source.RoleType__c, 
		Source.Name__C, 
		Source.LegalName__c, 
		Source.AltName__c, 
		Source.EmailAddress__c, 
		Source.BillToLocation__c, 
		Source.TaxLocation__c, 
		Source.CEBillToLocation__c, 
		Source.CollectorOID__c, 
		Source.CollectorName__c, 
		Source.PermanentCollectionAssignmentFlag__c, 
		Source.LastChangeDateTime__c, 
		Source.LastChangeOperator__c
    );