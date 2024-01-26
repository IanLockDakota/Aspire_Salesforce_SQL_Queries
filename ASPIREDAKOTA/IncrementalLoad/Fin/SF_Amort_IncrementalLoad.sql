-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(HOUR, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

MERGE INTO Amort_ASPIRE__c_upsert AS Target
USING (SELECT DISTINCT
	null AS ID,
	s.RefOid AS ContractOid__c,
	OppID.opportunityID AS OpportunityID__c,
	s.ScheduleOid AS ScheduleOid__c,
	li.lineitemoid AS lineitemoid__c,
	CONVERT(DATE, LI.EventDate) AS Date__c, 
	LI.Note AS Source__c,
	CASE WHEN LI.IsLoan = 1 THEN LI.EventAmount ELSE '' END AS AmountFinanced__c,
	CASE WHEN LI.IsPayment = 1 THEN '' ELSE CAST(100 * LI.NewRate AS varchar(50)) END AS Rate__c,
	CASE WHEN LI.IsPayment = 1 THEN LI.EventAmount ELSE '0.00' END AS Payment__c,
	LI.InterestAccrued AS Interest__c, 
	LI.Principal AS Principal__c, 
	LI.Balance AS Balance__c,
	li.LastChangeDateTime AS LastChangeDateTime__c,
	li.LastChangeOperator AS LastChangeOperator__c
	FROM 
		[ASPIRESQL].[AspireDakota].[Amortization].[Schedule] AS S
		INNER JOIN [ASPIRESQL].[AspireDakota].[Amortization].[LineItem] AS LI ON S.ScheduleOid = LI.ScheduleOid
		LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON s.RefOid = c.ContractOid
	LEFT OUTER JOIN
		(SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
			FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
			LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
			[ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
			WHERE GF.oid = 23
			GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppID ON amort.contractOID = OppID.ContractOID
	WHERE 
		(S.RefType = 1) AND (li.LastChangeDateTime BETWEEN @start AND @end) AND (OppID.opportunityID IS NOT NULL)) AS Source
ON target.LineItemOID__c = source.LineItemOID__c

WHEN MATCHED THEN
    UPDATE SET
		Target.ScheduleOid__c = Source.ScheduleOid__c,
		Target.OpportunityID__c = Source.OpportunityID__c,
		Target.Date__c = Source.Date__c,
		Target.Source__c = Source.Source__c,
		Target.AmountFinanced__c = Source.AmountFinanced__c,
		Target.Rate__c = Source.Rate__c,
		Target.Payment__c = Source.Payment__c,
		Target.Interest__c = Source.Interest__c,
		Target.Principal__c = Source.Principal__c,
		Target.Balance__c = Source.Balance__c,
		Target.LastChangeDateTime__c = Source.LastChangeDateTime__c,
		Target.LastChangeOperator__c = Source.LastChangeOperator__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
		OpportunityID__c,		
		LineItemOID__c,
		ScheduleOid__c,
		Date__c,
		Source__c,
		AmountFinanced__c,
		Rate__c,
		Payment__c,
		Interest__c,
		Principal__c,
		Balance__c,
		LastChangeDateTime__c,
		LastChangeOperator__c

    ) VALUES (
        Source.ID,
		Source.OpportunityID__c,
		Source.LineItemOID__c,
		Source.ScheduleOid__c,
		Source.Date__c,
		Source.Source__c,
		Source.AmountFinanced__c,
		Source.Rate__c,
		Source.Payment__c,
		Source.Interest__c,
		Source.Principal__c,
		Source.Balance__c,
		Source.LastChangeDateTime__c,
		Source.LastChangeOperator__c
    );