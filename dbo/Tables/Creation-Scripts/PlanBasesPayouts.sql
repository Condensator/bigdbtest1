SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PlanBasesPayouts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayOnFeeIncome] [bit] NOT NULL,
	[PayoutDescription] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CalculationMethod] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PlanBaseId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PlanBasesPayouts]  WITH CHECK ADD  CONSTRAINT [EPlanBase_PlanBasesPayouts] FOREIGN KEY([PlanBaseId])
REFERENCES [dbo].[PlanBases] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PlanBasesPayouts] CHECK CONSTRAINT [EPlanBase_PlanBasesPayouts]
GO
