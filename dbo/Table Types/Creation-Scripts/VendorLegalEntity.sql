CREATE TYPE [dbo].[VendorLegalEntity] AS TABLE(
	[IsApproved] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsOnHold] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CumulativeFundingLimit_Amount] [decimal](16, 2) NOT NULL,
	[CumulativeFundingLimit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
