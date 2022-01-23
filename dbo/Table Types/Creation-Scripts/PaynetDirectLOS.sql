CREATE TYPE [dbo].[PaynetDirectLOS] AS TABLE(
	[PaynetCustomerName] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaynetCustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ConfidenceIndicator] [int] NULL,
	[MainAddress] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[SSN] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[PaynetDirectDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
