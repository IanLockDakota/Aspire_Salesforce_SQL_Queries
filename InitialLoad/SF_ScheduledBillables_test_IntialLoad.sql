/*
Name: ScheduledBillables

ASPIRE SQLS Table Dependencies:
    - RecurringBillable
    - PaymentStream
    - PaymentStreamContractItem
    - Contract
    - GenericField
    - cdataGenericValue

Salesforce Backups Table Dependencies:
    - Scheduled_Billables_ASPIRE__c_upsert


SF Object Dependencies:
    - Scheduled_Billables_ASPIRE__c

Last change: 12/5/2023

Other Notes:
    - 
*/

MERGE INTO Scheduled_Billables_ASPIRE__c_upsert AS Target
USING (SELECT
	NULL as ID,
	RB.contractOID AS contractOID__c,
	OppIDTable.opportunityID as Opportunity__c,
    RB.ScheduleDefinitionOID AS ScheduleDefinitionOID__c,
	RB.RecurringBillableOid AS RecurringBillableOid__c,
	RB.IsFollowingRent AS IsFollowingRent__c,
	RB.IsCombinedWithRent AS IsCombinedWithRent__c,
	RB.IsProcessAsEFT AS IsProcessAsEFT__c,
	RB.IsBillAfterTermination AS IsBillAfterTermination__c,
	TC.description AS TCTransCDesc__C,
    RB.Description AS TransCDesc__c,
	PS.PaymentStreamOID AS PaymentStreamOID__c,
	PS.StartDate AS StartDate__c,
	PS.Occurrences AS Occurrences__c,
    /*HOW MANY REMAINING - uninvoiced*/
	PS.Frequency AS Frequency__c,
	PS.isInvoiced AS isInvoiced__c,
    PSCI.PaymentStreamContractItemOID AS PaymentStreamContractItemOID__c,
	PSCI.Amount AS Amount__c,
	PSCI.OnStreamTaxAmount AS OnStreamTaxAmount__c,
	PSCI.Amount + PSCI.OnStreamTaxAmount AS TtlAmt__C,
	CASE
		WHEN (c.isTerminated = 1) THEN NULL
		WHEN (c.isTerminated = 0) AND (ps.isInvoiced = 0) AND (ps.startDate > GETDATE()) THEN ps.StartDate
		ELSE NULL
	END as NextPaymentDate__c,
	PS.LastChangeDateTime AS LastChangeDateTime__c,
	PS.LastChangeOperator AS LastChangeOperator__c
    FROM
        [ASPIRESQL].[AspireDakotaTest].[dbo].[RecurringBillable] RB LEFT OUTER JOIN
        [ASPIRESQL].[AspireDakotaTest].[dbo].[PaymentStream] PS ON RB.ScheduleDefinitionOid = PS.ScheduleDefinitionOid INNER JOIN
        [ASPIRESQL].[AspireDakotaTest].[dbo].[TransactionCode] TC ON rb.transactioncodeOID = tc.transactioncodeOID LEFT OUTER JOIN
        (SELECT
            PaymentStreamContractItemOID,
            PaymentStreamOID,
            Amount,
            OnStreamTaxAmount
        FROM
            [ASPIRESQL].[AspireDakotaTest].[dbo].[PaymentStreamContractItem]
        ) AS PSCI ON ps.PaymentStreamOid = psci.PaymentStreamOID LEFT OUTER JOIN
        [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON RB.contractOID = c.contractOID LEFT OUTER JOIN
        (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS OpportunityID
                          FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GenericField] GF 
                          LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                          [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                          WHERE GF.oid = 23
                          GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIDTable ON OppIDTable.contractOid = c.contractOID
                          WHERE NOT Rb.description = 'ERROR'
        ) AS Source ON Target.PaymentStreamOID__c = Source.PaymentStreamOID__c


WHEN MATCHED THEN
    UPDATE SET
        Target.Opportunity__c = Source.Opportunity__c,
        Target.ScheduleDefinitionOID__c = Source.ScheduleDefinitionOID__c,
        Target.RecurringBillableOid__c = Source.RecurringBillableOid__c,
        Target.IsFollowingRent__c = Source.IsFollowingRent__c,
        Target.IsCombinedWithRent__c = Source.IsCombinedWithRent__c,
        Target.IsProcessAsEFT__c = Source.IsProcessAsEFT__c,
        Target.IsBillAfterTermination__c = Source.IsBillAfterTermination__c,
        Target.TCTransCDesc__C = Source.TCTransCDesc__C,
        Target.TransCDesc__c = Source.TransCDesc__c,
        Target.StartDate__c = Source.StartDate__c,
        Target.Occurrences__c = Source.Occurrences__c,
        Target.Frequency__c = Source.Frequency__c,
        Target.isInvoiced__c = Source.isInvoiced__c,
        Target.PaymentStreamContractItemOID__c = Source.PaymentStreamContractItemOID__c,
        Target.Amount__c = Source.Amount__c,
        Target.OnStreamTaxAmount__c = Source.OnStreamTaxAmount__c,
        Target.TtlAmt__C = Source.TtlAmt__C,
        Target.NextPaymentDate__c = Source.NextPaymentDate__c,
        Target.LastChangeDateTime__c = Source.LastChangeDateTime__c,
        Target.LastChangeOperator__c = Source.LastChangeOperator__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        ScheduleDefinitionOID__c,
        RecurringBillableOid__c,
        IsFollowingRent__c,
        IsCombinedWithRent__c,
        IsProcessAsEFT__c,
        IsBillAfterTermination__c,
        TCTransCDesc__C,
        TransCDesc__c,
        PaymentStreamOID__c,
        StartDate__c,
        Occurrences__c,
        Frequency__c,
        isInvoiced__c,
        PaymentStreamContractItemOID__c,
        Amount__c,
        OnStreamTaxAmount__c,
        TtlAmt__C,
        NextPaymentDate__c,
        LastChangeDateTime__c,
        LastChangeOperator__c

    ) VALUES (
        source.ID,
        source.Opportunity__c,
        source.ScheduleDefinitionOID__c,
        source.RecurringBillableOid__c,
        source.IsFollowingRent__c,
        source.IsCombinedWithRent__c,
        source.IsProcessAsEFT__c,
        source.IsBillAfterTermination__c,
        source.TCTransCDesc__C,
        source.TransCDesc__c,
        source.PaymentStreamOID__c,
        source.StartDate__c,
        source.Occurrences__c,
        source.Frequency__c,
        source.isInvoiced__c,
        source.PaymentStreamContractItemOID__c,
        source.Amount__c,
        source.OnStreamTaxAmount__c,
        source.TtlAmt__C,
        source.NextPaymentDate__c,
        source.LastChangeDateTime__c,
        source.LastChangeOperator__c
    
    );



/*
	CASE
		WHEN ps.isInvoiced = 0 THEN 
			(CASE
				WHEN c.isTerminated = 1 THEN NULL
				WHEN c.isterminated = 0 THEN PS.startDate
				ELSE NULL
			END)
		WHEN ps.isInvoiced = 1 THEN NULL
		ELSE NULL
	END as NextPaymentDate__c
*/