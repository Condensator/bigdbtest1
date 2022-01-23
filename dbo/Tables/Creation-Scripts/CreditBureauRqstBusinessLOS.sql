SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauRqstBusinessLOS](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ResponseUniqueNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditBureauRqstBusinessId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauRqstBusinessLOS]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstBusiness_CreditBureauRqstBusinessLOS] FOREIGN KEY([CreditBureauRqstBusinessId])
REFERENCES [dbo].[CreditBureauRqstBusinesses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauRqstBusinessLOS] CHECK CONSTRAINT [ECreditBureauRqstBusiness_CreditBureauRqstBusinessLOS]
GO
