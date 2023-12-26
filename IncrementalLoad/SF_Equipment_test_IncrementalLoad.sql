/*
Name: NetInvestment

ASPIRE SQLS Table Dependencies:
    - Contract
    - ContractEquipment
    - EquipmentID
    - ContractItem
    - ContractDisposedAsset
    - EquipmentLocationHistory
    - Location
    - PaymentStreamContractItem
    - GenericField
    - cdataGenericValue
    - Equipment (used in the subquery EquipInfo)
    - InvoiceDetail (used in the subquery Equipfin)
    - InvoicePaymentHistory (used in the subquery Equipfin)


Salesforce Backups Table Dependencies:
    - Equipment_ASPIRE__c_upsert

SF Object Dependencies:
    - Equipment_ASPIRE__c

Last change: 12/5/2023

Other Notes:
    - I believe termatDPD is the only field that needs to be added.
*/

-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(HOUR, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

MERGE INTO Equipment_ASPIRE__c_upsert AS Target
USING (SELECT
    NULL AS ID,
    c.ContractOID AS ContractOID__C,
    OppIDTable.opportunityID AS Opportunity__c,
    eid.EquipmentOID AS EquipmentOID__c,
    /*eid.EquipmentIDOID AS EquipmentIDOID__c,*/
    eid.serialnumber AS SerialNumber__c,
	CONCAT(ISNULL((NULLIF(el.addr_line1,' ') + ', '),''),ISNULL((NULLIF(el.addr_line2,' ') + ', '),''),ISNULL((NULLIF(el.addr_line3,' ') + ', '),''),el.city, ', ', el.state) as EquipmentLocation__c,
	CASE 
        WHEN PaystreamCI.IsTerminated = 1 OR NOT (cda.DisposalType IS NULL) 
        THEN 0 
        ELSE PaystreamCI.Amount 
    END AS PaymentAmount__C, 
    CASE 
        WHEN PaystreamCI.IsTerminated = 1 OR NOT (cda.DisposalType IS NULL) 
        THEN 0 
        ELSE PaystreamCI.OnStreamTaxAmount 
    END AS PaymentTaxAmount__C,
    cda.BillThroughDate AS BillThroughDate__c,
    CASE
		WHEN cda.DisposalType IS NULL THEN 'Not Disposed'
		WHEN cda.DisposalType = 'Sale' THEN 'Sale'
		WHEN cda.DisposalType = 'Inventory' THEN 'Inventory'
		WHEN cda.DisposalType = 'Abandon' THEN 'Abandon'
		ELSE 'ERROR'
	END AS DisposalType__c, 
    cda.DisposalAmount AS DisposalAmount__c,
	Equipfin.duedate as SaleDate__C,
	equipfin.PostDate AS PostDate__c,
	equipfin.AppliedDate AS AppliedDate__c,
    ce.LastChangeOperator AS ceLastChangeOperator__c,
    ce.LastChangeDateTime AS ceLastChangeDateTime__c,
    ce.DriverOperator AS DriverOperator__c 
FROM
    [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c LEFT OUTER JOIN
    [ASPIRESQL].[AspireDakotaTest].[dbo].[ContractEquipment] ce ON c.contractOID = ce.contractOID INNER JOIN
    [ASPIRESQL].[AspireDakotaTest].[dbo].[EquipmentID] eid ON ce.Equipmentoid = eid.EquipmentOid LEFT OUTER JOIN
	[ASPIRESQL].[AspireDakotaTest].[dbo].[ContractItem] CI ON ce.ContractEquipmentOid = ci.ContractEquipmentOid LEFT OUTER JOIN
	[ASPIRESQL].[AspireDakotaTest].[dbo].[ContractDisposedAsset] cda ON ci.ContractItemOid = cda.ContractItemOid LEFT OUTER JOIN
	(SELECT
		elh.contractOID,
		elh.equipmentOId,
		elh.startDate,
		elh.locationOID,
		l.city,
		l.state,
        l.addr_line1,
        l.addr_line2,
        l.addr_line3,
		ROW_NUMBER() OVER (PARTITION BY elh.equipmentOId ORDER BY elh.startDate DESC) AS RowNum
	FROM
		[ASPIRESQL].[AspireDakotaTest].[dbo].[EquipmentLocationHistory] elh LEFT OUTER JOIN
		[ASPIRESQL].[AspireDakotaTest].[dbo].[Location] l on elh.LocationOid = l.oid
	) AS el ON eid.EquipmentOid = el.EquipmentOid LEFT OUTER JOIN
	(SELECT        
							PaymentStreamContractItem.ContractItemOid, 
							PaymentStreamContractItem.Amount, 
							PaymentStreamContractItem.OnStreamTaxAmount, 
							PaymentStreamContractItem.IsTerminated, 
							PaymentStreamContractItem.PaymentStreamContractItemOid
						FROM            
							[ASPIRESQL].[AspireDakotaTest].[dbo].[PaymentStreamContractItem] 
							INNER JOIN (
								SELECT        
									ContractItemOid, 
									MAX(PaymentStreamContractItemOid) AS PaymentStreamContractItemOid
								FROM            
									[ASPIRESQL].[AspireDakotaTest].[dbo].[PaymentStreamContractItem] AS PaymentStreamContractItem_1
								GROUP BY 
									ContractItemOid
							) AS Maxpaystream 
							ON PaymentStreamContractItem.ContractItemOid = Maxpaystream.ContractItemOid 
							AND PaymentStreamContractItem.PaymentStreamContractItemOid = Maxpaystream.PaymentStreamContractItemOid
					) AS PaystreamCI ON PaystreamCI.ContractItemOid = ci.ContractItemOid LEFT OUTER JOIN
                        (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
                            FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GenericField] GF 
                            LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid
                            LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                            WHERE GF.oid = 23
                            GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                        ) AS OppIDTable ON c.ContractOid = OppIDTable.ContractOID LEFT OUTER JOIN
                        (SELECT cda.contractOID, cda.contractitemOID, cda.disposaltype, cda.disposalamount, cda.invoicedetailOid, id.duedate, iph.PostDate, MAX(iph.AppliedDate) as AppliedDate
                            FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[ContractDisposedAsset] cda LEFT OUTER JOIN
                            [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoiceDetail] ID on cda.InvoiceDetailOid = id.InvoiceDetailOid LEFT OUTER JOIN
                            [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoicePaymentHistory] iph on id.InvoiceDetailOid = iph.InvoiceDetailOid
                            GROUP BY cda.contractOID, cda.contractitemOID, cda.disposaltype, cda.disposalamount, 
                            cda.invoicedetailOid, id.duedate, iph.PostDate) AS Equipfin ON cda.ContractItemOid = Equipfin.contractitemOID
WHERE
	(c.CompanyOid = 1) 
    AND (c.IsBooked = 1)
	AND (el.rownum = 1)
	AND (ci.ContractItemTypeOid = 1)
    AND (ce.LastChangeDateTime BETWEEN @start AND @end))  AS Source
ON Target.EquipmentOID__c = Source.EquipmentOID__c


/*Upsert capabilities*/

WHEN MATCHED THEN
    UPDATE SET
        Target.EquipmentOID__c = Source.EquipmentOID__c,
        Target.serialnumber__c = Source.serialnumber__c,
        Target.PaymentAmount__C = Source.PaymentAmount__C,
        Target.BillThroughDate__c = Source.BillThroughDate__c,
        Target.DisposalType__c = Source.DisposalType__c,
        Target.DisposalAmount__c = Source.DisposalAmount__c,
        Target.SaleDate__C = Source.SaleDate__C,
        Target.PostDate__c = Source.PostDate__c,
        Target.AppliedDate__c = Source.AppliedDate__c,
        Target.ceLastChangeOperator__c = source.ceLastChangeOperator__c,
        Target.ceLastChangeDateTime__c = source.ceLastChangeDateTime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        EquipmentOID__c,
        serialnumber__c,
        PaymentAmount__C,
        BillThroughDate__c,
        DisposalType__c,
        DisposalAmount__c,
        SaleDate__C,
        PostDate__c,
        AppliedDate__c,
        ceLastChangeOperator__c,
        ceLastChangeDateTime__c

    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.EquipmentOID__c,
        Source.serialnumber__c,
        Source.PaymentAmount__C,
        Source.BillThroughDate__c,
        Source.DisposalType__c,
        Source.DisposalAmount__c,
        Source.SaleDate__C,
        Source.PostDate__c,
        Source.AppliedDate__c,
        Source.ceLastChangeOperator__c,
        Source.ceLastChangeDateTime__c
    );


/* LCDT COMPARISON CHECK 

SELECT Contract.ContractOid, Contract.StatusDate AS startDate, ContractItem.ContractItemOid, ContractEquipment.ContractEquipmentOid, PaymentStreamContractItem.PaymentStreamContractItemOid, ContractEquipment.EquipmentOid, 
                  EquipmentId.SerialNumber, ContractDisposedAsset.ContractDisposedAssetOid, ContractItem.LastChangeDateTime AS [ci.LCDT], ContractEquipment.LastChangeDateTime AS [ce.LCDT], 
                  PaymentStreamContractItem.LastChangeDateTime AS [psci.LCDT], EquipmentId.LastChangeDateTime AS [eid.LCDT], ContractDisposedAsset.LastChangeDateTime AS [cda.LCDT], CASE
        WHEN DATEDIFF(hour, ContractEquipment.LastChangeDateTime, EquipmentId.LastChangeDateTime) < 6 THEN 'LESS THAN 6H'
        WHEN DATEDIFF(hour, ContractEquipment.LastChangeDateTime, EquipmentId.LastChangeDateTime) > 6 THEN 'MORE THAN 6H'
        ELSE 'ERROR'
    END AS 'ContractEquipment vs EquipmentId datediff',
	CASE
        WHEN ContractEquipment.LastChangeDateTime < EquipmentId.LastChangeDateTime THEN 'EquipmentId.LastChangeDateTime'
        WHEN ContractEquipment.LastChangeDateTime > EquipmentId.LastChangeDateTime THEN 'ContractEquipment.LastChangeDateTime'
        ELSE 'ERROR'
    END AS 'ContractEquipment <>= EquipmentId LCDT'
FROM     Contract LEFT OUTER JOIN
                  ContractDisposedAsset ON Contract.ContractOid = ContractDisposedAsset.ContractOid AND Contract.ContractOid = ContractDisposedAsset.ContractOid LEFT OUTER JOIN
                  ContractEquipment ON Contract.ContractOid = ContractEquipment.ContractOid LEFT OUTER JOIN
                  ContractItem ON Contract.ContractOid = ContractItem.ContractOid AND ContractDisposedAsset.ContractItemOid = ContractItem.ContractItemOid AND 
                  ContractEquipment.ContractEquipmentOid = ContractItem.ContractEquipmentOid LEFT OUTER JOIN
                  Equipment ON ContractEquipment.EquipmentOid = Equipment.EquipmentOid LEFT OUTER JOIN
                  EquipmentId ON Equipment.EquipmentOid = EquipmentId.EquipmentOid LEFT OUTER JOIN
                  EquipmentLocationHistory ON Contract.ContractOid = EquipmentLocationHistory.ContractOid AND Equipment.EquipmentOid = EquipmentLocationHistory.EquipmentOid LEFT OUTER JOIN
                  Location ON Contract.RemitToOid = Location.oid AND Contract.BillToLocationOid = Location.oid AND Contract.EquipmentLocationOid = Location.oid AND Contract.TaxLocationOid = Location.oid AND 
                  ContractEquipment.BilltoLocationOid = Location.oid AND ContractItem.BillToLocationOid = Location.oid AND ContractItem.LocationOid = Location.oid AND EquipmentLocationHistory.LocationOid = Location.oid LEFT OUTER JOIN
                  PaymentStreamContractItem ON ContractItem.ContractItemOid = PaymentStreamContractItem.ContractItemOid
ORDER BY Contract.ContractOid

*/