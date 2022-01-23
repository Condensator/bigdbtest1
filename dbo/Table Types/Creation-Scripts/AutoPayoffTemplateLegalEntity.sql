CREATE TYPE [dbo].[AutoPayoffTemplateLegalEntity] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[OperatingLeasePayoffGLTemplateId] [bigint] NULL,
	[CapitalLeasePayoffGLTemplateId] [bigint] NULL,
	[InventoryBookDepGLTemplateId] [bigint] NULL,
	[TaxDepDisposalGLTemplateId] [bigint] NULL,
	[PayoffReceivableCodeId] [bigint] NULL,
	[BuyoutReceivableCodeId] [bigint] NULL,
	[SundryReceivableCodeId] [bigint] NULL,
	[AutoPayoffTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
