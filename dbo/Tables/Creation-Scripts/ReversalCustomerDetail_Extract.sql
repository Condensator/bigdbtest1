SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReversalCustomerDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[ClassCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CustomerNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxRegistrationNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ISOCountryCode] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PartyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
