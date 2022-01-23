SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BookDepreciationEnMasseUpdateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CostBasis_Amount] [decimal](16, 2) NOT NULL,
	[CostBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Salvage_Amount] [decimal](16, 2) NOT NULL,
	[Salvage_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginDate] [date] NOT NULL,
	[EndDate] [date] NULL,
	[RemainingLifeInMonths] [int] NOT NULL,
	[TerminatedDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BookDepreciationId] [bigint] NOT NULL,
	[BookDepreciationEnMasseUpdateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BookDepreciationEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EBookDepreciationEnMasseUpdate_BookDepreciationEnMasseUpdateDetails] FOREIGN KEY([BookDepreciationEnMasseUpdateId])
REFERENCES [dbo].[BookDepreciationEnMasseUpdates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BookDepreciationEnMasseUpdateDetails] CHECK CONSTRAINT [EBookDepreciationEnMasseUpdate_BookDepreciationEnMasseUpdateDetails]
GO
ALTER TABLE [dbo].[BookDepreciationEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EBookDepreciationEnMasseUpdateDetail_BookDepreciation] FOREIGN KEY([BookDepreciationId])
REFERENCES [dbo].[BookDepreciations] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciationEnMasseUpdateDetails] CHECK CONSTRAINT [EBookDepreciationEnMasseUpdateDetail_BookDepreciation]
GO
