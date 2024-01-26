MERGE INTO Customer_And_Related_Collections__c_upsert AS Target
USING (SELECT DISTINCT
	NULL AS ID,
	ph.OID AS PhoneOID__c,
	e.oid AS EntityOID__C,
	ISNULL(ph.phone_type, NULL) AS PhoneType__c,
	ISNULL(ph.phone_num, NULL) AS PhoneNumber__c,
	ISNULL(ph.extension, NULL) AS Extension__c,
	ph.is_primary AS PrimaryPhone__c,
	ph.LastchangeOperator AS phLastchangeOperator__c,
	ph.LastChangeDateTime AS phLastChangeDateTime__c
FROM
	[ASPIRESQL].[AspireDakota].[dbo].[Entity] e
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Phone] ph ON e.oid = ph.entt_oid
WHERE
	(ph.oid IS NOT NULL)) AS Source
ON Target.PhoneOID__c = Source.PhoneOID__c

WHEN MATCHED THEN
    UPDATE SET
		Target.EntityOID__C = Source.EntityOID__C,
		Target.PhoneType__c = Source.PhoneType__c,
		Target.PhoneNumber__c = Source.PhoneNumber__c,
		Target.Extension__c = Source.Extension__c,
		Target.PrimaryPhone__c = Source.PrimaryPhone__c,
		Target.phLastchangeOperator__c = Source.phLastchangeOperator__c,
		Target.phLastChangeDateTime__c = Source.phLastChangeDateTime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
		PhoneOID__c,
		EntityOID__C, 
		PhoneOID__c,
		PhoneType__c,
		PhoneNumber__c,
		Extension__c,
		PrimaryPhone__c,
		phLastchangeOperator__c,
		phLastChangeDateTime__c

    ) VALUES (
        Source.ID,
		Source.PhoneOID__c,
		Source.EntityOID__C, 
		Source.PhoneOID__c,
		Source.PhoneType__c,
		Source.PhoneNumber__c,
		Source.Extension__c,
		Source.PrimaryPhone__c,
		Source.phLastchangeOperator__c,
		Source.phLastChangeDateTime__c

    );