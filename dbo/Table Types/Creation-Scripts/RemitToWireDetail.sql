CREATE TYPE [dbo].[RemitToWireDetail] AS TABLE(
	[IsBeneficiary] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsCorrespondent] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ACHOriginatorID] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
