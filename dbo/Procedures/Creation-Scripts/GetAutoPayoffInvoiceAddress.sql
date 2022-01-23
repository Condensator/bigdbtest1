SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAutoPayoffInvoiceAddress]
(
	 @AutoPayoffInvoiceInputs AutoPayoffInvoiceAddressInput READONLY
)
AS
BEGIN
SET NOCOUNT ON;

		SELECT DISTINCT
			LeaseFinanceId = Lease.Id
			,LegalEntityName = Entity.[Name]
			,LegalEntityAddressLine1 = ISNULL(LEAddress.AddressLine1, LAddress.AddressLine1) 
			,LegalEntityAddressLine2 = ISNULL(LEAddress.AddressLine2, LAddress.AddressLine2) 
			,LegalEntityAddressLine3 = ISNULL(LEAddress.City, LAddress.City)
			,LegalEntityAddressLine4 = ISNULL(LEState.ShortName + ' ', LState.ShortName + ' ') + ISNULL(LEAddress.PostalCode, LAddress.PostalCode)
			,CustomerName = BillTo.CustomerBillToName
			,CustomerAddressLine1 = CAddress.AddressLine1
			,CustomerAddressLine2 = CAddress.AddressLine2
			,CustomerAddressLine3 = CAddress.City
			,CustomerAddressLine4 = ISNULL(CState.ShortName + ' ', '') + ISNULL(CAddress.PostalCode, '')
			,ContactPhone = Replace(Replace(isnull(LContact.PhoneNumber1, LEContact.PhoneNumber1), '-', ''), ' ', '')
			,ContactEmail = ISNULL(LContact.EMailId, LEContact.EMailId)
			,WebAddress = Entity.LessorWebAddress
			,CustomerComments = SUBSTRING(Customer.InvoiceComment, 1, 200)
			,CustomerInvoiceCommentBeginDate = Customer.InvoiceCommentBeginDate
			,CustomerInvoiceCommentEndDate = Customer.InvoiceCommentEndDate
			,AttentionLine = CContact.FullName
		FROM @AutoPayoffInvoiceInputs Input
			JOIN LeaseFinances Lease ON Input.LeaseFinanceId = Lease.Id 
			JOIN LegalEntities Entity ON Lease.LegalEntityId = Entity.Id
			JOIN BillToes BillTo ON Input.BillToId = BillTo.Id
			JOIN Parties Party ON BillTo.CustomerId = Party.Id
			JOIN Customers Customer ON Party.Id = Customer.Id
			JOIN RemitToes RemitTo ON Input.RemitToId = RemitTo.Id 
			JOIN PartyAddresses CAddress ON BillTo.BillingAddressId = CAddress.Id
			LEFT JOIN States CState ON CAddress.StateId = CState.Id
			LEFT JOIN LegalEntityAddresses LEAddress ON RemitTo.LegalEntityAddressId = LEAddress.Id
			LEFT JOIN PartyAddresses LAddress ON RemitTo.PartyAddressId = LAddress.Id
			LEFT JOIN States LEState ON LEAddress.StateId = LEState.Id
			LEFT JOIN States LState ON LAddress.StateId = LState.Id
			LEFT JOIN PartyContacts CContact ON BillTo.BillingContactPersonId = CContact.Id
			LEFT JOIN LegalEntityContacts LEContact ON RemitTo.LegalEntityContactId = LEContact.Id
			LEFT JOIN PartyContacts LContact ON RemitTo.PartyContactId = LContact.Id;

END

GO
