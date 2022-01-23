SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PayaleInvoiceOtherCostReport]
(
@AsOfDate DATETIME
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
With CTE_PayableInvoiceOtherCostDetail As
(
Select PayableInvoices.Id, SUM(PayableInvoiceOtherCosts.Amount_Amount) [OtherCostAmount],Amount_Currency[OtherCostCurrency], PayableInvoiceOtherCosts.AllocationMethod, CostTypes.Name From PayableInvoices
Inner Join PayableInvoiceOtherCosts On PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id
Left Join CostTypes On CostTypes.Id = PayableInvoiceOtherCosts.CostTypeId
Where PayableInvoiceOtherCosts.IsActive = 1 And PayableInvoices.DueDate <= @AsOfDate
Group By PayableInvoices.Id, PayableInvoiceOtherCosts.AllocationMethod, CostTypes.Name,Amount_Currency
)
Select PayableInvoices.Id [PayableInvoiceId],
PayableInvoices.InvoiceNumber,
PayableInvoices.DueDate [Invoice Due Date],
PayableInvoices.Status [Vendor Invoice Status],
PayableInvoices.InvoiceTotal_Amount [Invoice Total],
PayableInvoices.InvoiceTotal_Currency[Invoice Total Currency],
Parties.PartyNumber [Vendor Number],
Parties.PartyName [Vendor Name],
PartyAddresses.AddressLine1
+ CASE WHEN PartyAddresses.AddressLine2 IS NOT NULL AND PartyAddresses.AddressLine2 <> '' THEN ' ' + PartyAddresses.AddressLine2  ELSE '' END
+ CASE WHEN PartyAddresses.City IS NOT NULL AND PartyAddresses.City <> '' THEN ' ' + PartyAddresses.City ELSE '' END
+ CASE WHEN PartyAddresses.Division IS NOT NULL AND PartyAddresses.Division <> '' THEN ' ' + PartyAddresses.Division ELSE '' END
+ CASE WHEN States.ShortName IS NOT NULL AND States.ShortName <> '' THEN ' ' + States.ShortName ELSE '' END
+ CASE WHEN PartyAddresses.PostalCode IS NOT NULL AND PartyAddresses.PostalCode <> '' THEN ' ' + PartyAddresses.PostalCode ELSE '' END
+ CASE WHEN Countries.ShortName IS NOT NULL AND Countries.ShortName <> '' THEN ' ' + Countries.ShortName ELSE '' END [Address],
CTE_PayableInvoiceOtherCostDetail.AllocationMethod,
CTE_PayableInvoiceOtherCostDetail.Name [Cost Type Name],
PayableInvoices.InitialExchangeRate,
CTE_PayableInvoiceOtherCostDetail.OtherCostAmount [Amount],
CTE_PayableInvoiceOtherCostDetail.OtherCostCurrency[Amount_Currency],
CTE_PayableInvoiceOtherCostDetail.OtherCostAmount * PayableInvoices.InitialExchangeRate [Amount In LC],
ContractCurrency.Name[AmountInLC_Currency]
From PayableInvoices
Join Parties On PayableInvoices.VendorId = Parties.Id
Join PartyAddresses on Parties.id = PartyAddresses.PartyId
Join States on States.Id = PartyAddresses.StateId
Join Countries on Countries.Id = States.CountryId
Join CTE_PayableInvoiceOtherCostDetail On PayableInvoices.Id = CTE_PayableInvoiceOtherCostDetail.Id
Join Currencies ContractCurrency On ContractCurrency.Id = PayableInvoices.ContractCurrencyId
Where PartyAddresses.IsActive = 1  And PartyAddresses.IsMain = 1  And PayableInvoices.DueDate <= @AsOfDate
END

GO
