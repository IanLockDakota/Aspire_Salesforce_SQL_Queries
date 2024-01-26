MERGE INTO Customer_And_Related_Collections__c_upsert AS Target
USING (SELECT
	NULL AS ID,
	c.contractOID AS ContractOID__C,
	OppIDTable.OpportunityID AS Opportunity__c,
	e.collectorOID AS collectorOID__c,
	e2.name AS CollectorName__c,
	e.PermanentCollectionAssignmentFlag AS PermanentCollectionAssignmentFlag__c,
	e.LastChangeOperator__c,
	e.LastChangeDateTime__c
FROM
	[ASPIRESQL].[AspireDakota].[dbo].[Contract] C
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Entity] E ON c.entityOID = e.oid
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Entity] e2 ON e.CollectorOid = e2.oid
	LEFT OUTER JOIN
		(SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
    	FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
   		LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
   		[ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
   		WHERE GF.oid = 23
    	GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIDTable ON c.contractOID = OppIDTable.contractOID
WHERE
	(OppIDTable.opportunityID IS NOT NULL)) AS Source
ON Target.ContractOID__C = Source.ContractOID__C

WHEN MATCHED THEN
    UPDATE SET
		Target.Opportunity__c = Source.Opportunity__c,
		Target.CollectorOID__c = Source.CollectorOID__c,
		Target.CollectorName__c = Source.CollectorName__c,
		Target.PermanentCollectionAssignmentFlag__c = Source.PermanentCollectionAssignmentFlag__c,
		Target.LastChangeOperator__c = Source.LastChangeOperator__c,
		Target.LastChangeDateTime__c = Source.LastChangeDateTime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID, 
		ContractOID__C, 
		Opportunity__c, 
		CollectorOID__c, 
		CollectorName__c, 
		PermanentCollectionAssignmentFlag__c, 
		LastChangeDateTime__c, 
		LastChangeOperator__c

    ) VALUES (
        Source.ID, 
		Source.ContractOID__C, 
		Source.Opportunity__c, 
		Source.CollectorOID__c, 
		Source.CollectorName__c, 
		Source.PermanentCollectionAssignmentFlag__c, 
		Source.LastChangeDateTime__c, 
		Source.LastChangeOperator__c
    );