

MERGE INTO InvoiceHeader_ASPIRE__c_upsert AS Target
USING (SELECT DISTINCT
    NULL AS ID,
	c.contractOID AS contractOID__c,
	OppIDTable.opportunityID AS opportunity__c,
	p.paymentOID AS paymentOID__c,
    p.amount AS amount__c,
    p.LastChangeOperator AS PLastChangeOperator__c,
    p.LastChangeDateTime AS PLastChangeDatetime__c
FROM 
	[ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] C 
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Payment] P ON c.contractOID = p.contractOID
    LEFT OUTER JOIN
	 (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
                                  FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GenericField] GF 
                                  LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON c.ContractOid = OppIDTable.ref_oid
    WHERE
	p.paymentOID IS NOT NULL) AS Source
ON Target.PaymentOID__c = Source.PaymentOID__c

WHEN MATCHED THEN
    UPDATE SET
        Target.opportunity__c = Source.opportunity__c,
        Target.amount__c = Source.amount__c,
        Target.PLastChangeOperator__c = Source.PLastChangeOperator__c,
        Target.PLastChangeDatetime__c = Source.PLastChangeDatetime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        PaymentOID__c,
        amount__c,
        PLastChangeOperator__c,
        PLastChangeDatetime__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.PaymentOID__c,
        Source.amount__c,
        Source.PLastChangeOperator__c,
        Source.PLastChangeDatetime__c
    );
