-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(HOUR, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

MERGE INTO Customer_And_Related_Collections__c_upsert AS Target
USING (SELECT
	NULL AS ID,
	c.contractOID AS ContractOID__C,
	OppIDTable.Opportunity AS Opportunity__c,
	chen.entt_oid AS EntityOID__C, 
	r.descr AS RoleType__c,
	e.name AS Name__C,
	e.legal_name AS LegalName__c,
	e.alt_name AS AltName__c,
	cbtlloc.FullAddress AS BillToLocation__c,
	ctxloc.FullAddress AS TaxLocation__c,
	celoc.FullAddress AS CEBillToLocation__c,
	e.email_addr AS EmailAddress__c,
	ph.OID AS PhoneOID__c,
	ISNULL(ph.phone_type, NULL) AS PhoneType__c,
	ISNULL(ph.phone_num, NULL) AS PhoneNumber__c,
	ISNULL(ph.extension, NULL) AS Extension__c,
	ph.is_primary AS PrimaryPhone__c,
	CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE e.CollectorOid END AS CollectorOID__c,
    CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE collector.name END AS CollectorName__c,
    CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE e.PermanentCollectionAssignmentFlag END AS PermanentCollectionAssignmentFlag__c,
	e.LastchangeOperator AS entLastchangeOperator__c,
	e.LastChangeDateTime AS entLastChangeDateTime__c,
	ph.LastchangeOperator AS phLastchangeOperator__c,
	ph.LastChangeDateTime AS phLastChangeDateTime__c
FROM
	[ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[ChildEntity] chen ON chen.ref_oid = c.contractOID
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[role] r ON r.oid = chen.role_oid
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Entity] e ON chen.entt_oid = e.oid
	LEFT OUTER JOIN
		(SELECT DISTINCT
			e.CollectorOid,
			e2.name
		FROM 
			[ASPIRESQL].[AspireDakotaTest].[dbo].[Entity] e
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Entity] e2 ON e.collectorOID = e2.oid
		WHERE
			e2.name IS NOT NULL) AS collector ON e.collectorOID = collector.CollectorOid
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Phone] ph ON chen.entt_oid = ph.entt_oid
	LEFT OUTER JOIN
		(SELECT 
			c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
		FROM 
			[ASPIRESQL].[AspireDakotaTest].[dbo].[GenericField] GF 
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid 
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
		WHERE 
			GF.oid = 23
		GROUP BY 
			c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppID ON c.contractOID = OppID.ContractOid
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			c.BillToLocationOid,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress
		FROM
			[ASPIRESQL].[AspireDakotaTest].[dbo].[contract] c
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[contractEquipment] ce ON c.contractOID = ce.ContractOid
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Location] loc ON c.BillToLocationOid = loc.oid) AS cbtlloc ON c.contractOID = cbtlloc.contractOID
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			c.TaxLocationOid,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress
		FROM
			[ASPIRESQL].[AspireDakotaTest].[dbo].[contract] c
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Location] loc ON c.TaxLocationOid = loc.oid) AS ctxloc ON c.contractOID = ctxloc.contractOID
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			ce.BilltoLocationOid AS ceBillToLocationOID,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress
		FROM
			[ASPIRESQL].[AspireDakotaTest].[dbo].[contract] c
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[contractEquipment] ce ON c.contractOID = ce.ContractOid
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Location] loc ON ce.BilltoLocationOid = loc.oid) AS celoc ON c.contractOID = celoc.contractOID
	LEFT OUTER JOIN
		(SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
    	FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GenericField] GF 
   		LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
   		[ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
   		WHERE GF.oid = 23
    	GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIDTable ON c.contractOID = OppIDTable.contractOID
WHERE
	(chen.entt_OID <> 1) AND (r.descr <> 'Collector') AND ((e.LastChangeDateTime BETWEEN @start AND @end) OR (p.LastChangeDateTime BETWEEN @start AND @end))) AS Source
ON Target.PhoneOID__c = Source.PhoneOID__c

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
		Target.PhoneType__c = Source.PhoneType__c,
		Target.PhoneNumber__c = Source.PhoneNumber__c,
		Target.Extension__c = Source.Extension__c,
		Target.PrimaryPhone__c = Source.PrimaryPhone__c,
		Target.CollectorOID__c = Source.CollectorOID__c,
		Target.CollectorName__c = Source.CollectorName__c,
		Target.PermanentCollectionAssignmentFlag__c = Source.PermanentCollectionAssignmentFlag__c,
		Target.entLastchangeOperator__c = Source.entLastchangeOperator__c,
		Target.entLastChangeDateTime__c = Source.entLastChangeDateTime__c,
		Target.phLastchangeOperator__c = Source.phLastchangeOperator__c,
		Target.phLastChangeDateTime__c = Source.phLastChangeDateTime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
       	EntityOID__C,
		RoleType__c,
		Name__C,
		LegalName__c,
		AltName__c,
		BillToLocation__c,
		TaxLocation__c,
		CEBillToLocation__c,
		EmailAddress__c,
		PhoneOID__c,
		PhoneType__c,
		PhoneNumber__c,
		Extension__c,
		PrimaryPhone__c,
		CollectorOID__c,
		CollectorName__c,
		PermanentCollectionAssignmentFlag__c,
		entLastchangeOperator__c,
		entLastChangeDateTime__c,
		phLastchangeOperator__c,
		phLastChangeDateTime__c


    ) VALUES (
        Source.ID,
       	Source.EntityOID__C,
		Source.RoleType__c,
		Source.Name__C,
		Source.LegalName__c,
		Source.AltName__c,
		Source.BillToLocation__c,
		Source.TaxLocation__c,
		Source.CEBillToLocation__c,
		Source.EmailAddress__c,
		Source.PhoneOID__c,
		Source.PhoneType__c,
		Source.PhoneNumber__c,
		Source.Extension__c,
		Source.PrimaryPhone__c,
		Source.CollectorOID__c,
		Source.CollectorName__c,
		Source.PermanentCollectionAssignmentFlag__c,
		Source.entLastchangeOperator__c,
		Source.entLastChangeDateTime__c,
		Source.phLastchangeOperator__c,
		Source.phLastChangeDateTime__c
    );