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
    [ASPIRESQL].[AspireDakota].[dbo].[Contract] c LEFT OUTER JOIN
    [ASPIRESQL].[AspireDakota].[dbo].[ContractEquipment] ce ON c.contractOID = ce.contractOID INNER JOIN
    [ASPIRESQL].[AspireDakota].[dbo].[EquipmentID] eid ON ce.Equipmentoid = eid.EquipmentOid LEFT OUTER JOIN
	[ASPIRESQL].[AspireDakota].[dbo].[ContractItem] CI ON ce.ContractEquipmentOid = ci.ContractEquipmentOid LEFT OUTER JOIN
	[ASPIRESQL].[AspireDakota].[dbo].[ContractDisposedAsset] cda ON ci.ContractItemOid = cda.ContractItemOid LEFT OUTER JOIN
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
		[ASPIRESQL].[AspireDakota].[dbo].[EquipmentLocationHistory] elh LEFT OUTER JOIN
		[ASPIRESQL].[AspireDakota].[dbo].[Location] l on elh.LocationOid = l.oid
	) AS el ON eid.EquipmentOid = el.EquipmentOid LEFT OUTER JOIN
	(SELECT        
							PaymentStreamContractItem.ContractItemOid, 
							PaymentStreamContractItem.Amount, 
							PaymentStreamContractItem.OnStreamTaxAmount, 
							PaymentStreamContractItem.IsTerminated, 
							PaymentStreamContractItem.PaymentStreamContractItemOid
						FROM            
							[ASPIRESQL].[AspireDakota].[dbo].[PaymentStreamContractItem] 
							INNER JOIN (
								SELECT        
									ContractItemOid, 
									MAX(PaymentStreamContractItemOid) AS PaymentStreamContractItemOid
								FROM            
									[ASPIRESQL].[AspireDakota].[dbo].[PaymentStreamContractItem] AS PaymentStreamContractItem_1
								GROUP BY 
									ContractItemOid
							) AS Maxpaystream 
							ON PaymentStreamContractItem.ContractItemOid = Maxpaystream.ContractItemOid 
							AND PaymentStreamContractItem.PaymentStreamContractItemOid = Maxpaystream.PaymentStreamContractItemOid
					) AS PaystreamCI ON PaystreamCI.ContractItemOid = ci.ContractItemOid LEFT OUTER JOIN
                        (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
                            FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
                            LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid
                            LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                            WHERE GF.oid = 23
                            GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                        ) AS OppIDTable ON c.ContractOid = OppIDTable.ContractOID LEFT OUTER JOIN
                        (SELECT cda.contractOID, cda.contractitemOID, cda.disposaltype, cda.disposalamount, cda.invoicedetailOid, MAX(id.duedate) AS DueDate, MAX(iph.PostDate) as PostDate, MAX(iph.AppliedDate) as AppliedDate
                            FROM [ASPIRESQL].[AspireDakota].[dbo].[ContractDisposedAsset] cda LEFT OUTER JOIN
                            [ASPIRESQL].[AspireDakota].[dbo].[InvoiceDetail] ID on cda.InvoiceDetailOid = id.InvoiceDetailOid LEFT OUTER JOIN
                            [ASPIRESQL].[AspireDakota].[dbo].[InvoicePaymentHistory] iph on id.InvoiceDetailOid = iph.InvoiceDetailOid
                            GROUP BY cda.contractOID, cda.contractitemOID, cda.disposaltype, cda.disposalamount, 
                            cda.invoicedetailOid) AS Equipfin ON cda.ContractItemOid = Equipfin.contractitemOID
WHERE
	(c.CompanyOid = 1) 
    AND (c.IsBooked = 1)
	AND (el.rownum = 1)
	AND (ci.ContractItemTypeOid = 1)
    AND (c.ContractId NOT LIKE '%R%')
    AND (ce.LastChangeDateTime BETWEEN @start AND @end)
    AND (OppIDTable.opportunityID IS NOT NULL))  AS Source
ON Target.EquipmentOID__c = Source.EquipmentOID__c


/*Upsert capabilities*/

WHEN MATCHED THEN
    UPDATE SET
        Target.Opportunity__c = Source.Opportunity__c,
        Target.serialnumber__c = Source.serialnumber__c,
        Target.EquipmentLocation__c = Source.EquipmentLocation__c,
        Target.PaymentAmount__C = Source.PaymentAmount__C,
        Target.PaymentTaxAmount__C = Source.PaymentTaxAmount__C,
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
		EquipmentLocation__c,
        PaymentAmount__C,
		PaymentTaxAmount__C,
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
		Source.EquipmentLocation__c,
        Source.PaymentAmount__C,
		Source.PaymentTaxAmount__C,
        Source.BillThroughDate__c,
        Source.DisposalType__c,
        Source.DisposalAmount__c,
        Source.SaleDate__C,
        Source.PostDate__c,
        Source.AppliedDate__c,
        Source.ceLastChangeOperator__c,
        Source.ceLastChangeDateTime__c
    );