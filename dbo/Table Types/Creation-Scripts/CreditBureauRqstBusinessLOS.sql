CREATE TYPE [dbo].[CreditBureauRqstBusinessLOS] AS TABLE(
	[ResponseUniqueNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LosTransactionNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BureauCustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[BureauCustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ConfidenceIndicator] [decimal](5, 2) NULL,
	[MainAddress] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[SSN] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Address] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[StateName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Zip] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreditBureauRqstBusinessId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
