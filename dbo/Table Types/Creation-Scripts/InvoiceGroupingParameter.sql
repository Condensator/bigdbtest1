CREATE TYPE [dbo].[InvoiceGroupingParameter] AS TABLE(
	[InvoiceGroupingCategory] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AllowBlending] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[IsSystemDefined] [bit] NOT NULL,
	[IsParent] [bit] NOT NULL,
	[Blending] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[ReceivableCategoryId] [bigint] NOT NULL,
	[BlendReceivableCategoryId] [bigint] NULL,
	[BlendWithReceivableTypeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
