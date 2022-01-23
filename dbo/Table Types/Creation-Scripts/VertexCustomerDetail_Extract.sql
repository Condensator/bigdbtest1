CREATE TYPE [dbo].[VertexCustomerDetail_Extract] AS TABLE(
	[CustomerId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ISOCountryCode] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ClassCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TaxRegistrationNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
