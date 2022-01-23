SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractCollectionDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[OneToThirtyDaysLate] [int] NOT NULL,
	[ThirtyPlusDaysLate] [int] NOT NULL,
	[SixtyPlusDaysLate] [int] NOT NULL,
	[NinetyPlusDaysLate] [int] NOT NULL,
	[OneHundredTwentyPlusDaysLate] [int] NOT NULL,
	[TotalOneToThirtyDaysLate] [int] NOT NULL,
	[TotalThirtyPlusDaysLate] [int] NOT NULL,
	[TotalSixtyPlusDaysLate] [int] NOT NULL,
	[TotalNinetyPlusDaysLate] [int] NOT NULL,
	[TotalOneHundredTwentyPlusDaysLate] [int] NOT NULL,
	[InterestDPD] [int] NOT NULL,
	[RentOrPrincipalDPD] [int] NOT NULL,
	[MaturityDPD] [int] NOT NULL,
	[OverallDPD] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CalculateDeliquencyDetails] [bit] NOT NULL,
	[LegacyZeroPlusDaysLate] [int] NOT NULL,
	[LegacyThirtyPlusDaysLate] [int] NOT NULL,
	[LegacySixtyPlusDaysLate] [int] NOT NULL,
	[LegacyNinetyPlusDaysLate] [int] NOT NULL,
	[LegacyOneHundredTwentyPlusDaysLate] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractCollectionDetails]  WITH CHECK ADD  CONSTRAINT [EContractCollectionDetail_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ContractCollectionDetails] CHECK CONSTRAINT [EContractCollectionDetail_Contract]
GO
