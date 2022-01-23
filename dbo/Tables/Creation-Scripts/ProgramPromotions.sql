SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramPromotions](
	[PromotionCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsBlindPromotion] [bit] NOT NULL,
	[BeginDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[CommissionPercentage] [decimal](5, 2) NULL,
	[IsLessorServiced] [bit] NOT NULL,
	[IsLessorCollected] [bit] NOT NULL,
	[IsPerfectPay] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsNonNotification] [bit] NOT NULL,
	[ProgramRateCardId] [bigint] NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[ProgramDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramPromotions]  WITH CHECK ADD  CONSTRAINT [EProgramDetail_ProgramPromotions] FOREIGN KEY([ProgramDetailId])
REFERENCES [dbo].[ProgramDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramPromotions] CHECK CONSTRAINT [EProgramDetail_ProgramPromotions]
GO
ALTER TABLE [dbo].[ProgramPromotions]  WITH CHECK ADD  CONSTRAINT [EProgramPromotion_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[ProgramPromotions] CHECK CONSTRAINT [EProgramPromotion_BlendedItemCode]
GO
ALTER TABLE [dbo].[ProgramPromotions]  WITH CHECK ADD  CONSTRAINT [EProgramPromotion_ProgramRateCard] FOREIGN KEY([ProgramRateCardId])
REFERENCES [dbo].[ProgramRateCards] ([Id])
GO
ALTER TABLE [dbo].[ProgramPromotions] CHECK CONSTRAINT [EProgramPromotion_ProgramRateCard]
GO
